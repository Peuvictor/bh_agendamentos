# frozen_string_literal: true

module Provider
  class CalendarController < BaseController
    def show
      @business_hours = current_user.availability_periods.ordered.map do |period|
        {
          daysOfWeek: [period.weekday],
          startTime: period.start_label,
          endTime: period.end_label
        }
      end
    end

    def events
      starts_at, ends_at = requested_range
      render json: calendar_feed(starts_at, ends_at).events
    rescue ActionController::ParameterMissing, ArgumentError, TypeError
      render json: { error: 'Informe um período válido para consultar o calendário.' },
             status: :unprocessable_content
    end

    private

    def calendar_feed(starts_at, ends_at)
      ProviderCalendarEventFeed.new(
        provider: current_user,
        starts_at: starts_at,
        ends_at: ends_at,
        include_history: ActiveModel::Type::Boolean.new.cast(params[:include_history])
      )
    end

    def requested_range
      starts_at = Time.zone.iso8601(params.require(:start))
      ends_at = Time.zone.iso8601(params.require(:end))
      raise ArgumentError unless starts_at < ends_at

      [starts_at, ends_at]
    end
  end
end
