Rails.application.routes.draw do
  # 1. Se o usuário estiver logado, a Home é a lista de agendamentos dele (cliente)
  authenticated :user do
    root "appointments#index", as: :authenticated_root
  end

  # 2. Se NÃO estiver logado, a Home é a vitrine de serviços
  root "home#index"

  # 3. Rota VIP para o Painel do Prestador (localhost:3000/dashboard)
  get 'dashboard', to: 'appointments#dashboard', as: 'dashboard'
# Rota para ver o próprio perfil
  get 'perfil', to: 'profiles#show', as: 'perfil'

  # Rota do "Modo Deus" (Painel do Admin Geral)
  namespace :admin do
    get 'dashboard', to: 'dashboard#index', as: 'dashboard'
  end

  # 4. Outras rotas do sistema
  resources :appointments
  resources :services
  devise_for :users

  # 5. Rota para a Caixa de Entrada de testes (Letter Opener Web)
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Health check para o Docker
  get "up" => "rails/health#show", as: :rails_health_check
end
