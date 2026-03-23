Rails.application.routes.draw do
  # Se o usuário estiver logado, a home dele é a lista de agendamentos
  authenticated :user do
    root "appointments#index", as: :authenticated_root
  end

  # Se NÃO estiver logado, ele vê a página de marketing/bem-vindo
  root "home#index"

  resources :appointments
  resources :services
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check
end
