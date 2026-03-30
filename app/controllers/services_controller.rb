class ServicesController < ApplicationController
  # 1. Trava principal: Só entra quem estiver logado!
  before_action :authenticate_user!

  before_action :check_provider_role

  # 2. Executa o filtro de segurança antes destas ações
  before_action :set_service, only: %i[ show edit update destroy ]

  def index
    # Regra de Negócio: O prestador SÓ vê os serviços que pertencem a ele
    @services = current_user.services
  end

  def show
  end

  def new
    # Prepara um serviço novo já atrelado ao usuário logado
    @service = current_user.services.build
  end

  def edit
  end

  def create
    # Cria o serviço garantindo que o dono é o usuário atual (ignora hackers no formulário)
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
  def check_provider_role
    unless current_user.provider?
      redirect_to root_path, alert: "Acesso negado. Apenas prestadores podem acessar esta seção."
    end

    def set_service
      # A Mágica da Segurança: Busca o serviço APENAS dentro da lista do usuário logado!
      # Se ele tentar passar o ID do serviço de outro prestador, o Rails bloqueia.
      @service = current_user.services.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to services_path, alert: "Serviço não encontrado ou você não tem permissão."
    end

    def service_params
      # Removemos o :user_id daqui. O usuário não pode mandar isso pela tela.
      params.require(:service).permit(:nome, :descricao, :duracao_minutos, :preco)
    end
end
