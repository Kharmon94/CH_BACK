# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      namespace :auth do
        post "sign_in", to: "sessions#create"
        post "sign_up", to: "registrations#create"
        get "me", to: "me#show"
        get "google", to: "google#start"
        get "google/callback", to: "google#callback"
      end

      post "team_invites/:token/accept", to: "team_invites#accept"

      resources :teams, only: [ :index, :create, :show, :update ] do
        resources :memberships, only: [ :index, :create, :destroy ], controller: "team_memberships"
        resources :workspaces, only: [ :index, :create, :show, :update, :destroy ]
        resource :license, only: [ :show ], controller: "licenses"
        post "billing/checkout", to: "team_checkouts#create"
        post "billing/confirm", to: "team_checkouts#confirm"
      end

      resource :license, only: [ :show ]

      resources :linked_databases, only: [ :index, :create, :destroy ] do
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

      post "uploads", to: "uploads#create"

      namespace :admin do
        post "sign_in", to: "sessions#create"
        resources :users, only: [ :index, :show ]
        resources :teams, only: [ :index, :show, :update ]
      end

      namespace :stripe do
        post "webhook", to: "webhooks#create"
      end
    end
  end
end
