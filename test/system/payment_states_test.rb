# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../support/mercado_pago_system_helpers'

# These scenarios exercise the browser, the real Rails endpoints and persisted payment state.
# rubocop:disable-next Minitest/MultipleAssertions, Metrics/ClassLength
class PaymentStatesTest < ApplicationSystemTestCase
  include MercadoPagoSystemHelpers

  setup do
    skip 'Os estados do pagamento requerem Selenium' if Capybara.current_driver == :rack_test

    @client = users(:two)
    @service = services(:one)
    @previous_public_key = ENV.fetch('MERCADO_PAGO_PUBLIC_KEY', nil)
    @previous_webhook_secret = ENV.fetch('MERCADO_PAGO_WEBHOOK_SECRET', nil)
    ENV['MERCADO_PAGO_PUBLIC_KEY'] = 'TEST-system-public-key'
    ENV['MERCADO_PAGO_WEBHOOK_SECRET'] = 'system-webhook-secret'
    login_client
  end

  teardown do
    ENV['MERCADO_PAGO_PUBLIC_KEY'] = @previous_public_key
    ENV['MERCADO_PAGO_WEBHOOK_SECRET'] = @previous_webhook_secret
  end

  test 'approved card persists the payment and confirmed appointment' do
    appointment = create_pending_appointment
    gateway = FakeGateway.new(create_response: {
                                'id' => 'mp-system-approved',
                                'status' => 'approved'
                              })
    visit appointment_path(appointment)

    submit_browser_payment(gateway: gateway, method: 'credit_card', form_data: card_form_data) do
      assert_text 'Pagamento aprovado! Seu agendamento está confirmado.'
    end

    assert_predicate appointment.reload, :confirmado?
    assert_predicate appointment.payment, :aprovado?
    visit appointment_path(appointment)

    assert_text 'Agendamento Confirmado!'
    assert_no_selector '[data-controller="payment"]'
    assert_slot_occupied(appointment)
  end

  test 'rejected card keeps the reservation payable without persisting a payment' do
    appointment = create_pending_appointment
    gateway = FakeGateway.new(create_response: {
                                'status' => 'rejected',
                                'status_detail' => nil
                              })
    visit appointment_path(appointment)

    submit_browser_payment(gateway: gateway, method: 'credit_card', form_data: card_form_data) do
      assert_text 'Pagamento recusado pela operadora.'
    end

    assert_predicate appointment.reload, :pendente?
    assert_nil appointment.payment
    assert_selector '[data-controller="payment"]'
  end

  test 'card in process is not presented as approved and cannot be charged twice' do
    appointment = create_pending_appointment
    gateway = FakeGateway.new(create_response: {
                                'id' => 'mp-system-in-process',
                                'status' => 'in_process'
                              })
    visit appointment_path(appointment)

    submit_browser_payment(gateway: gateway, method: 'credit_card', form_data: card_form_data) do
      assert_text 'Pagamento em processamento. Aguarde a confirmação antes de tentar novamente.'
      assert_no_text 'Pagamento aprovado!'
    end

    assert_predicate appointment.reload, :pendente?
    assert_predicate appointment.payment, :pendente?
    visit appointment_path(appointment)

    assert_text 'Pagamento em processamento'
    assert_text 'Não é necessário realizar uma nova cobrança.'
    assert_no_selector '[data-controller="payment"]'
  end

  test 'pending PIX becomes confirmed through a signed webhook' do
    appointment = create_pending_appointment
    create_gateway = FakeGateway.new(create_response: pending_pix_response('mp-system-pix'))
    visit appointment_path(appointment)

    submit_browser_payment(gateway: create_gateway, method: 'pix', form_data: pix_form_data) do
      assert_selector '[data-role="pix-code"]', wait: 10
      assert_field type: 'text', with: '000201-system-pix'
    end

    payment = appointment.reload.payment

    assert_predicate payment, :pendente?
    sync_gateway = FakeGateway.new(fetch_responses: [gateway_payment(payment, 'approved')])

    post_signed_payment_webhook(payment: payment, gateway: sync_gateway)
    visit appointment_path(appointment)

    assert_text 'Agendamento Confirmado!'
    assert_predicate appointment.reload, :confirmado?
    assert_predicate payment.reload, :aprovado?
    assert_equal 'approved', WebhookDelivery.order(:created_at).last.remote_status
  end

  test 'rejected remote payment expires the reservation and releases its slot' do
    appointment = create_pending_appointment
    payment = create_payment(appointment: appointment, status: :pendente, transaction_id: 'mp-system-rejected')
    gateway = FakeGateway.new(fetch_responses: [gateway_payment(payment, 'rejected')])
    visit appointment_path(appointment)

    assert_text 'Pagamento em processamento'
    post_signed_payment_webhook(payment: payment, gateway: gateway)
    visit appointment_path(appointment)

    assert_text 'Expirado por falta de pagamento'
    assert_predicate appointment.reload, :cancelado?
    assert_predicate payment.reload, :rejeitado?
    assert_slot_released(appointment)
  end

  test 'refund remains final after a delayed approval webhook' do
    appointment = create_pending_appointment
    payment = create_payment(appointment: appointment, status: :aprovado, transaction_id: 'mp-system-refunded')
    appointment.update!(status: :confirmado)
    refund_gateway = FakeGateway.new(fetch_responses: [gateway_payment(payment, 'refunded')])

    post_signed_payment_webhook(payment: payment, gateway: refund_gateway)
    visit appointment_path(appointment)

    assert_text 'Pagamento reembolsado'
    assert_predicate appointment.reload, :reembolsado?
    assert_predicate payment.reload, :reembolsado?
    assert_no_selector '[data-controller="payment"]'

    delayed_gateway = FakeGateway.new(fetch_responses: [gateway_payment(payment, 'approved')])
    post_signed_payment_webhook(payment: payment, gateway: delayed_gateway)

    assert_predicate appointment.reload, :reembolsado?
    assert_predicate payment.reload, :reembolsado?
    assert_slot_released(appointment)
  end

  test 'overdue reservation without a payment shows expiration and releases its slot' do
    appointment = create_pending_appointment
    appointment.update_columns(expires_at: 1.minute.ago) # rubocop:disable Rails/SkipsModelValidations

    assert_equal :expired_without_payment, ExpireAppointmentService.new(appointment_id: appointment.id).call
    visit appointment_path(appointment)

    assert_text 'Expirado por falta de pagamento'
    assert_text 'este horário foi liberado'
    assert_no_selector '[data-controller="payment"]'
    assert_slot_released(appointment)
  end

  private

  def login_client
    visit new_user_session_path
    fill_in 'E-mail', with: @client.email
    fill_in 'Senha', with: 'password123'
    click_button 'Entrar'

    assert_current_path root_path, wait: 10
  end

  def create_pending_appointment
    Appointment.create!(
      client: @client,
      service: @service,
      start_time: 7.days.from_now.change(hour: 10, min: 0, sec: 0),
      status: :pendente
    )
  end

  def create_payment(appointment:, status:, transaction_id:)
    Payment.create!(
      appointment: appointment,
      amount: @service.preco,
      status: status,
      mp_transaction_id: transaction_id,
      idempotency_key: SecureRandom.uuid,
      expires_at: status == :pendente ? appointment.expires_at : nil
    )
  end

  def card_form_data
    {
      token: 'system-card-token',
      payment_method_id: 'visa',
      issuer_id: '1',
      installments: 1,
      payer: { email: @client.email }
    }
  end

  def pix_form_data
    {
      payment_method_id: 'pix',
      installments: 1,
      payer: { email: @client.email }
    }
  end

  def pending_pix_response(transaction_id)
    {
      'id' => transaction_id,
      'status' => 'pending',
      'point_of_interaction' => {
        'transaction_data' => {
          'qr_code' => '000201-system-pix',
          'qr_code_base64' => 'R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=='
        }
      }
    }
  end

  def assert_slot_occupied(appointment)
    replacement = appointment.dup
    replacement.status = :pendente

    assert_not replacement.valid?
    assert_includes replacement.errors[:base], 'Ops! O prestador já está atendendo outro cliente neste horário.'
  end

  def assert_slot_released(appointment)
    replacement = Appointment.new(
      client: @client,
      service: @service,
      start_time: appointment.start_time,
      status: :pendente
    )

    assert_predicate replacement, :valid?, replacement.errors.full_messages.to_sentence
  end
end
