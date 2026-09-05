class Admin::ServicesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!
  before_action :set_service, only: %i[archive reactivate]

  def index
    # Eager loading do user para evitar N+1
    @services = Service.includes(:user).all.order(created_at: :desc)
  end

  def archive
    @service.archive!(by_admin: true)
    redirect_to admin_services_path, notice: "Serviço arquivado pela administração."
  end

  def reactivate
    @service.reactivate!(by_admin: true)
    redirect_to admin_services_path, notice: "Serviço reativado pela administração."
  end

  private

  def set_service
    @service = Service.find(params[:id])
  end
end
