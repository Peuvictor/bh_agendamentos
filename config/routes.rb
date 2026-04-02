Rails.application.routes.draw do
  # 1. Se o usuário estiver logado, a Home é a lista de agendamentos dele (cliente)
  authenticated :user do
    root "appointments#index", as: :authenticated_root
  end

  # 2. Se NÃO estiver logado, a Home é a vitrine de serviços
  root "home#index"

  # 3. Rota VIP para o Painel do Prestador (localhost:3000/dashboard)
  get 'dashboard', to: 'appointments#dashboard', as: 'dashboard'

  # 4. Outras rotas do sistema
  resources :appointments
  resources :services
  devise_for :users

  # Health check para o Docker
  get "up" => "rails/health#show", as: :rails_health_check
end
