OnboardOnRails::Engine.routes.draw do
  namespace :admin do
    resources :tours do
      post :copy, on: :member
      resources :steps, except: [:index]
      resource :stats, only: [:show]
    end
    resources :lessons, only: [:index] do
      member do
        post :replay
      end
      collection do
        post :seed
        post :recreate
      end
    end
    root to: "tours#index"
  end

  namespace :api do
    resources :tours, only: [:index]
    resources :completions, only: [:create]
    resources :events, only: [:create]
  end

  get "selector_picker", to: "selector_picker#show"
end
