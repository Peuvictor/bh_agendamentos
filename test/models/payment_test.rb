require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "belongs to an appointment" do
    assert_equal appointments(:one), payments(:one).appointment
  end

  test "maps payment statuses" do
    payment = payments(:one)

    payment.status = :pendente
    assert payment.pendente?

    payment.status = :aprovado
    assert payment.aprovado?
  end

  test "appends refunded without changing existing payment statuses" do
    assert_equal 4, Payment.statuses.fetch("reembolsado")
  end

  test "requires a positive amount" do
    payment = payments(:one)
    payment.amount = 0

    assert_not payment.valid?
    assert payment.errors[:amount].any?
  end

  test "allows only one payment per appointment" do
    duplicate = Payment.new(
      appointment: payments(:one).appointment,
      amount: 50,
      status: :pendente,
      mp_transaction_id: "mp-new-transaction",
      idempotency_key: "new-idempotency-key"
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:appointment_id].any?
  end

  test "requires unique Mercado Pago and idempotency identifiers" do
    payment = Payment.new(
      appointment: appointments(:two),
      amount: 50,
      status: :pendente,
      mp_transaction_id: payments(:one).mp_transaction_id,
      idempotency_key: payments(:one).idempotency_key
    )

    assert_not payment.valid?
    assert payment.errors[:mp_transaction_id].any?
    assert payment.errors[:idempotency_key].any?
  end
end
