# frozen_string_literal: true

class ProviderCalendarEventFeed
  APPOINTMENT_COLORS = {
    'confirmado' => '#059669',
    'pendente' => '#d97706',
    'cancelado' => '#64748b',
    'reembolsado' => '#7c3aed'
  }.freeze
  BLOCK_COLOR = '#dc2626'

  def initialize(provider:, starts_at:, ends_at:, include_history: false)
    @provider = provider
    @starts_at = starts_at
    @ends_at = ends_at
    @include_history = include_history
  end

  def events
    (appointment_events + block_events).sort_by { |event| [event[:start], event[:id]] }
  end

  private

  attr_reader :provider, :starts_at, :ends_at, :include_history

  def appointment_events
    appointments.map { |appointment| appointment_event(appointment) }
  end

  # A estrutura segue o contrato de eventos do FullCalendar.
  def appointment_event(appointment)
    {
      id: "appointment-#{appointment.id}",
      title: "#{appointment.service.nome} · #{appointment.client.nome}",
      start: appointment.start_time.iso8601,
      end: appointment.end_time.iso8601,
      allDay: false,
      color: APPOINTMENT_COLORS.fetch(appointment.status),
      extendedProps: appointment_properties(appointment)
    }
  end

  def appointment_properties(appointment)
    {
      kind: 'appointment',
      clientName: appointment.client.nome,
      serviceName: appointment.service.nome,
      status: appointment.status,
      detailsUrl: Rails.application.routes.url_helpers.appointment_path(appointment)
    }
  end

  def appointments
    scope = provider.received_appointments
                    .includes(:client, :service)
                    .where('appointments.start_time < ? AND appointments.end_time > ?', ends_at, starts_at)
    scope = scope.where(status: %i[pendente confirmado]) unless include_history
    scope.order(:start_time)
  end

  def block_events
    availability_blocks.map { |block| block_event(block) }
  end

  def block_event(block)
    all_day = all_day?(block)
    {
      id: "availability-block-#{block.id}",
      title: block_title(block),
      start: event_time(block.starts_at, all_day),
      end: event_time(block.ends_at, all_day),
      allDay: all_day,
      color: BLOCK_COLOR,
      extendedProps: block_properties(block)
    }
  end

  def block_properties(block)
    {
      kind: 'availabilityBlock',
      reason: block.reason.presence || 'Sem motivo informado',
      serviceName: block.service&.nome,
      scope: block.service&.nome || 'Todos os serviços',
      editUrl: block.editable? ? Rails.application.routes.url_helpers.edit_provider_availability_block_path(block) : nil
    }
  end

  def availability_blocks
    provider.availability_blocks
            .includes(:service)
            .where('starts_at < ? AND ends_at > ?', ends_at, starts_at)
            .order(:starts_at)
  end

  def all_day?(block)
    block.starts_at == block.starts_at.beginning_of_day && block.ends_at == block.starts_at + 1.day
  end

  def event_time(time, all_day)
    all_day ? time.to_date.iso8601 : time.iso8601
  end

  def block_title(block)
    "Bloqueio · #{block.service&.nome || 'Todos os serviços'}"
  end
end
