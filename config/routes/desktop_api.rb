# frozen_string_literal: true

# Local engine routes — mounted only in RAILS_ENV=desktop
namespace :auth do
  get "me", to: "me#show"
  get "validate", to: "validate#show"
  post "sync", to: "desktop_sync#create"
end

get "local/discover", to: "local/discover#show"

resources :teams, only: [ :index ] do
  resources :workspaces, only: [ :index, :create ]
end

resources :linked_databases, only: [ :index, :create, :destroy ] do
  collection do
    post :locate
    get :discover
  end

  member do
    post :refresh
  end
end

resources :composers, only: [ :index, :show ] do
  collection do
    get :search
  end
end

resources :exports, only: [ :index, :create, :show ] do
  member do
    get :download
  end
end
