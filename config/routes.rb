Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post "register", to: "registrations#create"
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
      end

      resources :tasks, only: [ :index, :show, :create, :update, :destroy ]
    end
  end
  get "/health", to: "health#show"

  # Defines the root path route ("/")
  # root "posts#index"
end
