class Admin::ServicesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    # Eager loading do user para evitar N+1
    @services = Service.includes(:user).all.order(created_at: :desc)
  end

  def destroy
    @service = Service.find(params[:id])
    @service.destroy
    redirect_to admin_services_path, notice: "Serviço removido com sucesso."
  end
end
