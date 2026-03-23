class HomeController < ApplicationController
  # Não precisa estar logado para ver a home
  def index
    @services = Service.all.order(nome: :asc)
  end
end
