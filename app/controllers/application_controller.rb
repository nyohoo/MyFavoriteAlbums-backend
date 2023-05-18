class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pagenation
  #url_forを利用するために、rails_helperをincludeしている
  include Rails.application.routes.url_helpers
  require 'rspotify'
  require 'open-uri'

  before_action :skip_session

  protected
    def skip_session
      request.session_options[:skip] = true
    end
end 
