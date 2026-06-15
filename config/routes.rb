# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      if Rails.env.desktop?
        draw :desktop_api
      else
        draw :cloud_api
      end
    end
  end
end
