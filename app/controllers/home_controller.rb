class HomeController < ApplicationController
  def index
    # Eager loading para evitar N+1
    @services = Service.includes(user: :avatar_attachment).all

    # 1. Filtro por Texto (Nome do Serviço ou Prestador)
    if params[:query].present?
      @services = @services.joins(:user).where("services.nome ILIKE :q OR users.nome ILIKE :q", q: "%#{params[:query]}%")
    end

    # 2. 👇 NOVO: Filtro de Geolocalização (Bairro) 👇
    if params[:bairro].present?
      # Como o bairro está na tabela 'users', usamos o joins para acessar essa coluna
      @services = @services.joins(:user).where(users: { bairro: params[:bairro] })
    end

    # Ordenação padrão (mais recentes primeiro)
    @services = @services.order(created_at: :desc)
  end
end
