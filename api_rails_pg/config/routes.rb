Rails.application.routes.draw do
  scope module: :api do
    namespace :v1 do
      resources :companies do
        member do
          put :mark_deleted
          get :applies
        end
        resources :jobs
      end
      resources :jobs do
        member do
          get :geeks
          get :invited_geeks
        end
        resources :applies
      end
      resources :geeks do
        member do
          get :jobs
          get :invited_jobs
          get :companies
          put :resume
        end
        resources :applies
      end
      resources :applies do
        member do
          put :mark_read
          put :invite
        end
      end
    end
  end
  match '*path', to: 'application#catch_404', via: :all
  root 'application#catch_404'
end
