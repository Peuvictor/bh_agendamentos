require 'sidekiq/web'

Rails.application.routes.draw do
  # 1. REDIRECIONAMENTO DE HOME
  authenticated :user do
    root "appointments#index", as: :authenticated_root
  end
  root "home#index"

  # 2. ROTAS PÚBLICAS E PERFIL
  get '/vitrine', to: 'home#index', as: 'vitrine'
  get 'dashboard', to: 'appointments#dashboard', as: 'dashboard'
  get 'perfil', to: 'profiles#show', as: 'perfil'

  # 3. 🕴️ MODO DEUS (NAMESPACE ADMIN)
  namespace :admin do
    # 1. Atalho principal: /admin já cai no Dashboard
    root to: 'dashboard#index'
    get 'dashboard', to: 'dashboard#index', as: 'dashboard'

    # 2. Gestão de Usuários
    resources :users, only: [:index, :destroy]

    # 3. Gestão de Serviços (Substituindo os 'gets' genéricos)
    resources :services, only: [:index, :destroy]
  end

  # 4. DOMÍNIO: SERVIÇOS E AGENDAMENTOS
  resources :services do
    resources :appointments, only: [:new, :create]
    resources :reviews, only: [:index] # Ver avaliações do serviço
  end

  resources :appointments, only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch :update_status
    end
    # Criar avaliação para um agendamento específico
    resources :reviews, only: [:create]
  end

  # 5. INFRA E AUTENTICAÇÃO
  # Proteção do Sidekiq (Dica: Depois podemos restringir isso apenas a Admins)
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users
  devise_scope :user do
    get '/users', to: 'devise/registrations#new'
    get '/users/password', to: 'devise/passwords#new'
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
