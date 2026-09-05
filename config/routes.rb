require 'sidekiq/web'

Rails.application.routes.draw do
  # 1. REDIRECIONAMENTO DE HOME
  authenticated :user do
    root "appointments#index", as: :authenticated_root
  end
  root "home#index"

  # 2. ROTAS PÚBLICAS, PERFIL E DASHBOARD
  get '/vitrine', to: 'home#index', as: 'vitrine'
  get '/perfil', to: 'profiles#show', as: 'perfil'
  get '/dashboard', to: 'dashboard#index', as: 'dashboard'

  # 3. 🕴️ MODO DEUS (NAMESPACE ADMIN)
  namespace :admin do
    root to: 'dashboard#index'
    get 'dashboard', to: 'dashboard#index', as: 'dashboard'
    resources :users, only: [:index, :destroy]
    resources :services, only: :index do
      member do
        patch :archive
        patch :reactivate
      end
    end
  end

  # 4. DOMÍNIO: SERVIÇOS E AGENDAMENTOS
  resources :services, except: :destroy do
    member do
      patch :archive
      patch :reactivate
    end
    get :available_slots, on: :member, to: "appointments#available_slots"
    resources :appointments, only: [:new, :create]
    resources :reviews, only: [:index]
  end

  namespace :provider do
    resource :availability, only: %i[show update], controller: "availability"
    resources :availability_blocks, only: %i[create destroy]
  end

  resources :appointments, only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch :update_status
    end
    resources :reviews, only: [:create]
  end

  # 5. INFRA E AUTENTICAÇÃO
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users, controllers: { registrations: 'users/registrations' }
  devise_scope :user do
    get '/users', to: 'users/registrations#new'
    get '/users/password', to: 'devise/passwords#new'
  end

  # 6. PAGAMENTOS
  resources :payments, only: [:create]

  namespace :webhooks do
    post :mercado_pago, to: "mercado_pago#create"
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
