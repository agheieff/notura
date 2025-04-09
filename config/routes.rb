Rails.application.routes.draw do
  devise_for :users
  
  # Profile routes
  resource :profile, only: [:show, :edit, :update]
  
  # Languages and learning
  resources :languages, only: [:index, :show] do
    resources :profile_languages, only: [:create, :update, :destroy]
    resources :vocabulary_entries, only: [:index]
  end
  
  resources :profile_languages, only: [] do
    resources :language_goals, only: [:create, :update, :destroy]
    resources :user_vocabulary_entries, only: [:index]
  end
  
  resources :topics, only: [:index, :show]
  
  # Vocabulary system
  resources :vocabulary_entries, only: [:index, :show]
  
  resources :user_vocabulary_entries, only: [:index, :show, :create, :update] do
    member do
      post :record_review
    end
  end
  
  # Authentication and account routes
  get "dashboard", to: "dashboard#index", as: :user_root
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end