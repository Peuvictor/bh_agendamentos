class HomeController < ApplicationController
  def index
    # Se alguém digitou algo na barra de busca (parâmetro :query)
    if params[:query].present?
      # Fazemos um JOIN com a tabela de usuários para buscar tanto pelo nome do serviço quanto pelo nome do prestador (ex: "Corte" ou "Fabrício")
      @services = Service.joins(:user)
                         .where("services.nome ILIKE :q OR users.nome ILIKE :q", q: "%#{params[:query]}%")
                         .order(created_at: :desc)
    else
      # Se não tem busca, carrega tudo normal
      @services = Service.all.order(created_at: :desc)
    end
  end
end
