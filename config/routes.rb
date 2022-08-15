Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      namespace :auth do
        resources :sessions, only: %i[index]
      end
      mount_devise_token_auth_for 'User', at: 'auth', controllers: {
        omniauth_callbacks: 'overrides/omniauth_callbacks',
      }
      get 'users/:uid', param: :uid, to: 'users#show_user' 
      get 'users/:uid/posts', param: :uid, to: 'users#show_users_post'
      get 'users/:uid/likes', param: :uid, to: 'users#show_users_like'

      get 'posts/lists', param: :page, to: 'posts#index'
      get 'posts/:uuid', param: :uuid, to: 'posts#show'
      post 'posts', to: 'posts#create'
      delete 'posts', param: :uuid, to: 'posts#destroy'

      resources :likes, only: %i[create destroy]

      get '/search', to: 'songs#search'
      get '/add_search', to: 'songs#add_search'

      post '/tweets', to: 'tweets#create'
    end
  end
end
