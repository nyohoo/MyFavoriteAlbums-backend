Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      namespace :auth do
        resources :sessions, only: %i[index]
      end

      mount_devise_token_auth_for 'User', at: 'auth', controllers: {
        omniauth_callbacks: 'overrides/omniauth_callbacks',
        registrations: 'api/v1/auth/registrations'
      }

      get '/search', to: 'songs#search'
    end
  end
end
