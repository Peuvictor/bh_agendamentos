# frozen_string_literal: true

module Provider
  class AvailabilityController < BaseController
    def show
      load_availability
    end

    def update
      updater = ProviderScheduleUpdater.new(provider: current_user)
      raw_schedule = params[:schedule]&.permit!.to_h

      if updater.call(raw_schedule)
        redirect_to provider_availability_path, notice: t('provider.availability.updated')
      else
        redirect_to provider_availability_path, alert: updater.error
      end
    end

    private

    def load_availability
      @periods_by_weekday = current_user.availability_periods.ordered.group_by(&:weekday)
      @availability_blocks = current_user.availability_blocks
                                         .includes(:service)
                                         .active_from(Time.current)
                                         .order(:starts_at)
      @services = current_user.services.order(:nome)
    end
  end
end
