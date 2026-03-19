Rails.application.routes.draw do
  # A rota raiz que substitui a página padrão do Rails
  root "home#index"

  # Suas outras rotas do sistema
  resources :appointments
  resources :services
  devise_for :users

  # Rota de health check do Docker/Rails
  get "up" => "rails/health#show", as: :rails_health_check
end
