# frozen_string_literal: true

module Provider
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_provider!

    private

    def require_provider!
      return if current_user.provider?

      redirect_to root_path, alert: t('provider.access_denied')
    end
  end
end
