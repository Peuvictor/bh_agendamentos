# frozen_string_literal: true

module Provider
  class AvailabilityBlocksController < BaseController
    def create
      block = current_user.availability_blocks.build(block_attributes)

      if block.save
        redirect_to provider_availability_path, notice: t('provider.availability_blocks.created')
      else
        redirect_to provider_availability_path, alert: block.errors.full_messages.to_sentence
      end
    rescue ArgumentError, KeyError
      redirect_to provider_availability_path, alert: t('provider.availability_blocks.invalid_period')
    end

    def destroy
      current_user.availability_blocks.find(params[:id]).destroy!
      redirect_to provider_availability_path, notice: t('provider.availability_blocks.destroyed')
    end

    private

    def block_attributes
      attributes = availability_block_params
      date = Date.iso8601(attributes.fetch(:date))
      starts_at, ends_at = time_range(date, attributes)

      {
        service: selected_service(attributes[:service_id]),
        reason: attributes[:reason],
        starts_at: starts_at,
        ends_at: ends_at
      }
    end

    def availability_block_params
      params.require(:availability_block).permit(:date, :all_day, :start_time, :end_time, :service_id, :reason)
    end

    def time_range(date, attributes)
      return all_day_range(date) if ActiveModel::Type::Boolean.new.cast(attributes[:all_day])

      start_minute = AvailabilityPeriod.minute_from_time(attributes.fetch(:start_time))
      end_minute = AvailabilityPeriod.minute_from_time(attributes.fetch(:end_time))
      day_start = start_of_day(date)
      [day_start + start_minute.minutes, day_start + end_minute.minutes]
    end

    def all_day_range(date)
      day_start = start_of_day(date)
      [day_start, day_start + 1.day]
    end

    def start_of_day(date)
      Time.zone.local(date.year, date.month, date.day)
    end

    def selected_service(service_id)
      return if service_id.blank?

      current_user.services.find(service_id)
    end
  end
end
