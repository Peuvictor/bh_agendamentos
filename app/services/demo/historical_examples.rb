# frozen_string_literal: true

module Demo
  class HistoricalExamples
    def initialize(catalog, week)
      @catalog = catalog
      @week = week
      @client_id = catalog.users.fetch(:client).id
    end

    def call
      %i[haircut_beard haircut].each_with_index do |service_key, index|
        create_example(service_key, index)
      end
    end

    private

    def create_example(service_key, index)
      key = "history/#{index}"
      service = @catalog.services.fetch(service_key)
      appointment = Appointment.find_by(id: Records.id(key)) || import_appointment(service, key, index)
      Payments.create(appointment, key) if appointment.confirmado? || appointment.reembolsado?
      comment = index.zero? ? 'Atendimento pontual e muito caprichado!' : 'Ótimo corte, recomendo!'
      Records.create(Review, "review/#{key}", appointment: appointment, rating: 5, comment: comment)
    end

    def import_appointment(service, key, index)
      # Historical imports cannot use the normal future-only booking validation.
      # Explicit, fixed attributes stay confined to this demonstration loader.
      # rubocop:disable-next Rails/SkipsModelValidations
      Appointment.insert_all!([historical_attributes(service, key, index)])
      Appointment.find(Records.id(key))
    end

    def historical_attributes(service, key, index)
      start_time = (@week - 14.days + index.days).in_time_zone.change(hour: 9)
      {
        id: Records.id(key), client_id: @client_id, service_id: service.id,
        start_time: start_time, end_time: start_time + 1.hour, status: Appointment.statuses.fetch('confirmado'),
        expires_at: nil, created_at: start_time - 1.day, updated_at: start_time - 1.day
      }
    end
  end
end
