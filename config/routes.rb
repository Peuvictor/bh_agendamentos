Rails.application.routes.draw do
  # 1. Se o usuário estiver logado, a Home é o Dashboard de Agendamentos (como cliente)
  authenticated :user do
    root "appointments#index", as: :authenticated_root
  end

  # 2. Se NÃO estiver logado, a Home é a vitrine de serviços
  root "home#index"

  # 3. Rotas de Agendamentos com o Dashboard do Prestador
  resources :appointments do
    collection do
      get :dashboard # Rota: /appointments/dashboard
    end
  end

  # 4. Outras rotas do sistema
  resources :services
  devise_for :users

  # Health check para o Docker
  get "up" => "rails/health#show", as: :rails_health_check
end
