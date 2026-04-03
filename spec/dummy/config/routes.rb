Rails.application.routes.draw do
  mount OnboardOnRails::Engine, at: "/onboard"

  get "dashboard", to: "pages#dashboard"
  get "settings", to: "pages#settings"
  root to: "pages#dashboard"
end
