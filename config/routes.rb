Rails.application.routes.draw do
  root "application#index"
  get "up" => "rails/health#show"
  scope module: :api do
    namespace :v1, defaults: { format: :json } do
      resources :employees do
        member do
          get :chats
          put :mark_deleted
        end
        resources :memberships, :messages, only: [:index, :show, :create]
      end
      resources :chats do
        member do
          get :employees
          put :mark_deleted
        end
        resources :messages
        resources :memberships
      end
      resources :messages do
        put :mark_deleted, on: :member
      end
      resources :memberships do
        member do
          put :mark_deleted
          put :mark_read
          get :unread_messages
        end
      end
    end
  end
  match "*path", to: "application#catch_404", via: :all
end
