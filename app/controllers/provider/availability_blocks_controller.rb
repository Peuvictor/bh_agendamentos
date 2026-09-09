# frozen_string_literal: true

module Provider
  class AvailabilityBlocksController < BaseController
    before_action :set_block, only: %i[edit update]

    def edit
      return redirect_ended_block unless @block.editable?

      @block_form = AvailabilityBlockForm.new(@block)
      load_edit_services
    end

    def create
      block = current_user.availability_blocks.build(block_attributes)

      if save_block(block)
        redirect_to provider_availability_path, notice: t('provider.availability_blocks.created')
      else
        redirect_to provider_availability_path, alert: block.errors.full_messages.to_sentence
      end
    rescue ArgumentError, KeyError
      redirect_to provider_availability_path, alert: t('provider.availability_blocks.invalid_period')
    end

    def update
      @block_form = AvailabilityBlockForm.new(@block, availability_block_params)
      if @block_form.save
        redirect_to provider_availability_path, notice: t('provider.availability_blocks.updated'), status: :see_other
      else
        load_edit_services
        render :edit, status: :unprocessable_content
      end
    rescue AvailabilityBlockForm::EndedBlock
      redirect_ended_block
    end

    def destroy
      current_user.with_schedule_lock do
        current_user.availability_blocks.find(params[:id]).destroy!
      end
      redirect_to provider_availability_path, notice: t('provider.availability_blocks.destroyed')
    end

    private

    def save_block(block)
      current_user.with_schedule_lock { block.save }
    end

    def set_block
      @block = current_user.availability_blocks.find(params[:id])
    end

    def redirect_ended_block
      redirect_to provider_availability_path, alert: t('provider.availability_blocks.ended'), status: :see_other
    end

    def load_edit_services
      @services = current_user.services.active.order(:nome).to_a
      original_service = current_user.services.find_by(id: @block.service_id_in_database)
      @services << original_service if original_service&.archived?
    end

    def block_attributes
      attributes = availability_block_params
      starts_at, ends_at = AvailabilityBlockForm.new(current_user.availability_blocks.build, attributes).interval

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

    def selected_service(service_id)
      return if service_id.blank?

      current_user.services.active.find(service_id)
    end
  end
end
