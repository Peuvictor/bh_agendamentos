# frozen_string_literal: true

require 'test_helper'

module Provider
  # rubocop:disable-next Metrics/ClassLength
  class CalendarControllerTest < ActionDispatch::IntegrationTest
    setup do
      @provider = users(:one)
      @client = users(:two)
      @service = services(:one)
      sign_in @provider
    end

    # rubocop:disable-next Minitest/MultipleAssertions
    test 'shows the provider calendar with working periods' do
      get provider_calendar_url

      assert_response :success
      assert_select 'h1', text: 'Calendário'
      assert_select "[data-controller='provider-calendar']"
      assert_select "[data-provider-calendar-events-url-value='#{provider_calendar_events_path}']"
      assert_match 'daysOfWeek', response.body
    end

    # rubocop:disable-next Minitest/MultipleAssertions
    test 'returns active appointments and blocks intersecting the requested range' do
      start_time = future_time(days: 7, hour: 10)
      appointment = create_appointment(start_time: start_time, status: :confirmado)
      block = @provider.availability_blocks.create!(
        starts_at: start_time - 1.hour,
        ends_at: start_time + 15.minutes,
        reason: 'Consulta médica'
      )

      get provider_calendar_events_url, params: {
        start: (start_time + 5.minutes).iso8601,
        end: (start_time + 1.hour).iso8601
      }, as: :json

      assert_response :success
      events = response.parsed_body.index_by { |event| event.fetch('id') }
      appointment_event = events.fetch("appointment-#{appointment.id}")
      block_event = events.fetch("availability-block-#{block.id}")

      assert_equal 'appointment', appointment_event.dig('extendedProps', 'kind')
      assert_equal @client.nome, appointment_event.dig('extendedProps', 'clientName')
      assert_equal appointment_path(appointment), appointment_event.dig('extendedProps', 'detailsUrl')
      assert_equal 'availabilityBlock', block_event.dig('extendedProps', 'kind')
      assert_equal 'Consulta médica', block_event.dig('extendedProps', 'reason')
    end

    # rubocop:disable-next Minitest/MultipleAssertions
    test 'hides terminal appointments unless history is requested' do
      start_time = future_time(days: 8, hour: 9)
      active = create_appointment(start_time: start_time, status: :pendente)
      cancelled = create_appointment(start_time: start_time + 1.hour, status: :cancelado)
      refunded = create_appointment(start_time: start_time + 2.hours, status: :reembolsado)
      range = { start: start_time.beginning_of_day.iso8601, end: (start_time + 1.day).beginning_of_day.iso8601 }

      get provider_calendar_events_url, params: range, as: :json

      assert_response :success
      assert_equal ["appointment-#{active.id}"], response.parsed_body.pluck('id')

      get provider_calendar_events_url, params: range.merge(include_history: true), as: :json

      assert_response :success
      assert_equal [active, cancelled, refunded].map { |appointment| "appointment-#{appointment.id}" }.sort,
                   response.parsed_body.pluck('id').sort
    end

    test 'does not expose another providers calendar events' do
      other_provider = create_provider
      other_service = other_provider.services.create!(
        nome: 'Serviço de outro prestador',
        descricao: 'Não deve aparecer no calendário consultado',
        duration: 30,
        preco: 80
      )
      foreign_appointment = Appointment.create!(
        client: @client,
        service: other_service,
        start_time: future_time(days: 9, hour: 10),
        status: :confirmado
      )

      get provider_calendar_events_url, params: {
        start: 8.days.from_now.beginning_of_day.iso8601,
        end: 10.days.from_now.end_of_day.iso8601,
        include_history: true
      }, as: :json

      assert_response :success
      assert_not_includes response.parsed_body.pluck('id'), "appointment-#{foreign_appointment.id}"
    end

    # rubocop:disable-next Minitest/MultipleAssertions
    test 'serializes an all day block for a specific service' do
      date = 12.days.from_now.to_date
      day_start = Time.zone.local(date.year, date.month, date.day)
      block = @provider.availability_blocks.create!(
        service: @service,
        starts_at: day_start,
        ends_at: day_start + 1.day,
        reason: 'Feriado local'
      )

      get provider_calendar_events_url, params: {
        start: day_start.iso8601,
        end: (day_start + 1.day).iso8601
      }, as: :json

      event = response.parsed_body.find { |item| item.fetch('id') == "availability-block-#{block.id}" }

      assert_response :success
      assert event.fetch('allDay')
      assert_equal date.iso8601, event.fetch('start')
      assert_equal @service.nome, event.dig('extendedProps', 'scope')
    end

    # rubocop:disable-next Minitest/MultipleAssertions
    test 'returns only operational appointment data' do
      start_time = future_time(days: 10, hour: 10)
      appointment = create_appointment(start_time: start_time, status: :confirmado)

      get provider_calendar_events_url, params: {
        start: start_time.beginning_of_day.iso8601,
        end: start_time.end_of_day.iso8601
      }, as: :json

      event = response.parsed_body.find { |item| item.fetch('id') == "appointment-#{appointment.id}" }

      assert_response :success
      assert_nil event.dig('extendedProps', 'email')
      assert_nil event.dig('extendedProps', 'price')
      assert_nil event.dig('extendedProps', 'payment')
      assert_not_includes response.body, @client.email
    end

    # rubocop:disable-next Minitest/MultipleAssertions
    test 'rejects missing invalid or reversed ranges' do
      get provider_calendar_events_url, as: :json

      assert_response :unprocessable_content

      get provider_calendar_events_url, params: { start: 'invalid', end: 'also-invalid' }, as: :json

      assert_response :unprocessable_content

      get provider_calendar_events_url, params: { start: { invalid: true }, end: 1.day.from_now.iso8601 }, as: :json

      assert_response :unprocessable_content

      get provider_calendar_events_url,
          params: { start: 2.days.from_now.iso8601, end: 1.day.from_now.iso8601 }, as: :json

      assert_response :unprocessable_content
    end

    test 'rejects clients' do
      sign_out @provider
      sign_in @client

      get provider_calendar_url

      assert_redirected_to root_url
    end

    private

    def create_appointment(start_time:, status:)
      Appointment.create!(client: @client, service: @service, start_time: start_time, status: status)
    end

    def future_time(days:, hour:)
      date = days.days.from_now.to_date
      Time.zone.local(date.year, date.month, date.day, hour)
    end

    def create_provider
      User.create!(
        nome: 'Outro prestador',
        email: "outro-prestador-#{SecureRandom.hex(4)}@example.com",
        password: 'Teste123!',
        role: :provider,
        bairro: 'Savassi'
      )
    end
  end
end
