# frozen_string_literal: true

module Demo
  class Scenarios
    BOOKINGS = [
      [:haircut_beard, 0, 9, :confirmado], [:beard, 1, 10, :confirmado], [:haircut, 2, 14, :confirmado],
      [:beard, 0, 11, :pendente], [:haircut, 1, 15, :cancelado], [:haircut_beard, 2, 16, :reembolsado]
    ].freeze

    def initialize(catalog, week)
      @catalog = catalog
      @week = week
    end

    def call
      @catalog.users.fetch(:provider).with_schedule_lock do
        create_blocks
        BOOKINGS.each_with_index { |booking, index| create_booking(booking, index) }
        HistoricalExamples.new(@catalog, @week).call
      end
    end

    private

    def at(day, hour)
      (@week + day).in_time_zone.change(hour: hour)
    end

    def create_blocks
      block('general', nil, 0, 15)
      block('service', @catalog.services.fetch(:beard), 1, 14)
    end

    def block(key, service, day, hour)
      id = Records.id("#{@week}/block/#{key}")
      return if AvailabilityBlock.exists?(id: id)

      provider = @catalog.users.fetch(:provider)
      check_block_conflicts!(provider, day, hour)

      provider.availability_blocks.create!(id: id, service: service, starts_at: at(day, hour),
                                           ends_at: at(day, hour + 1),
                                           reason: block_reason(service))
    end

    def block_reason(service)
      service ? 'Manutenção dos materiais de barba' : 'Organização do espaço'
    end

    def check_block_conflicts!(provider, day, hour)
      return unless provider.received_appointments.where.not(status: %i[cancelado reembolsado])
                            .exists?(['start_time < ? AND end_time > ?', at(day, hour + 1), at(day, hour)])

      raise Seed::Error, 'Um atendimento existente ocupa o horário do novo bloqueio de demonstração.'
    end

    def create_booking(booking, index)
      key = "#{@week}/appointment/#{index}"
      appointment = Appointment.find_by(id: Records.id(key)) || new_booking(booking, key)
      Payments.create(appointment, key) if appointment.confirmado? || appointment.reembolsado?
    end

    def new_booking(booking, key)
      service_key, day, hour, status = booking
      service = @catalog.services.fetch(service_key)
      Records.create(Appointment, key, service: service, client: @catalog.users.fetch(:client),
                                       start_time: at(day, hour), status: status,
                                       refunded_at: status == :reembolsado ? Time.current : nil)
    end
  end
end
