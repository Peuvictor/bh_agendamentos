require 'sidekiq/web' # 1. DEPÊNDENCIA OBRIGATÓRIA

Rails.application.routes.draw do
  # 1. Se o usuário estiver logado, a Home é a lista de agendamentos dele
  authenticated :user do
    root "appointments#index", as: :authenticated_root
  end

  # 2. Se NÃO estiver logado, a Home é a vitrine de serviços
  root "home#index"

  # A ROTA DE FUGA: Uma URL fixa para a vitrine de serviços, independente do login
  get '/vitrine', to: 'home#index', as: 'vitrine'

  # 3. Rota VIP para o Painel do Prestador
  get 'dashboard', to: 'appointments#dashboard', as: 'dashboard'

  # Rota para ver o próprio perfil
  get 'perfil', to: 'profiles#show', as: 'perfil'

  # Rota do "Modo Deus" (Painel do Admin Geral)
  namespace :admin do
    get 'dashboard', to: 'dashboard#index', as: 'dashboard'
  end

  # ------------------------------------------------------------------
  # 4. As Rotas de Domínio (A Mágica do Aninhamento)
  # ------------------------------------------------------------------
  resources :services do
    # O cliente SÓ consegue chegar no formulário de agendamento se passar por um serviço
    resources :appointments, only: [:new, :create]
  end

  #  Rota customizada para atualizar o status do agendamento
  resources :appointments, only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch :update_status
    end
  end

  # ------------------------------------------------------------------
  # 👇 PAINEL DE CONTROLE DO SIDEKIQ 👇
  # Em produção, você deve proteger essa rota com autenticação de admin.
  # ------------------------------------------------------------------
  mount Sidekiq::Web => '/sidekiq'

  # ------------------------------------------------------------------
  # Configuração do Devise (Autenticação)
  # ------------------------------------------------------------------
  devise_for :users

  # Correção do erro de "rebote" (ActionController::RoutingError GET /users)
  devise_scope :user do
    get '/users', to: 'devise/registrations#new'
    get '/users/password', to: 'devise/passwords#new'
  end
  # ------------------------------------------------------------------

  # 5. Rota para a Caixa de Entrada de testes (Letter Opener Web)
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Health check para o Docker
  get "up" => "rails/health#show", as: :rails_health_check
end
