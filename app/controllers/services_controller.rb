class ServicesController < ApplicationController
  # 1. Trava principal: Só entra quem estiver logado!
  before_action :authenticate_user!

  # Descomente a linha abaixo quando seu usuário já for 'provider' no banco
  # before_action :check_provider_role

  # 2. Executa o filtro de segurança antes destas ações
  before_action :set_service, only: %i[ show edit update destroy ]

  def index
    # O prestador SÓ vê os serviços que pertencem a ele
    @services = current_user.services
  end

  def show
  end

  def new
    @service = current_user.services.build
  end

  def edit
  end

  def create
    @service = current_user.services.build(service_params)

    if @service.save
      redirect_to services_path, notice: "Serviço criado com sucesso, uai!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @service.update(service_params)
      redirect_to services_path, notice: "Serviço atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy!
    redirect_to services_path, notice: "Serviço removido com sucesso.", status: :see_other
  end

  private

  # Cada método agora tem seu próprio 'end' e não está um dentro do outro
  def check_provider_role
    unless current_user.provider?
      redirect_to root_path, alert: "Acesso negado. Apenas prestadores podem acessar esta seção."
    end
  end

  def set_service
    @service = current_user.services.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to services_path, alert: "Serviço não encontrado ou você não tem permissão."
  end

  def service_params
    params.require(:service).permit(:nome, :descricao, :duracao_minutos, :preco)
  end
end # Apenas UM 'end' para fechar a classe aqui no final!
