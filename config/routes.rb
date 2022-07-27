Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      namespace :auth do
        resources :sessions, only: %i[index]
      end

      mount_devise_token_auth_for 'User', at: 'auth', controllers: {
        omniauth_callbacks: 'overrides/omniauth_callbacks',
      }

      get '/search', to: 'songs#search'
      get '/get_albums', to: 'songs#get_albums'
      post '/post_albums', to: 'songs#post_albums'
    end
  end
end
