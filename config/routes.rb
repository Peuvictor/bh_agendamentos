Rails.application.routes.draw do
  root "home#index"

  # Removemos o 'only' para liberar as 7 rotas padrão (index, show, new, create, edit, update, destroy)
  resources :appointments

  resources :services
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check
end
