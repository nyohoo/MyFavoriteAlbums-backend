module Overrides

  class OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
    skip_before_action :skip_session

    def redirect_callbacks
      super
    end

    def omniauth_success
      super
      update_auth_header
    end

    def omniauth_failure
      super
    end

    protected
    def assign_provider_attrs(user, auth_hash)
      case auth_hash['provider']
      when 'twitter'
        user.assign_attributes({
          nickname: auth_hash['info']['nickname'],
          name: auth_hash['info']['name'],
          image: auth_hash['info']['image'].gsub(/_normal.jpg/, ".jpg"),
          email: auth_hash['info']['email'],
          access_token: auth_hash['credentials']['token'],
          access_token_secret: auth_hash['credentials']['secret']
        })
      else
        super
      end
    end

    def get_resource_from_auth_hash
      super
       # @resource.credentials = auth_hash["credentials"]
      # clean_resource
    end

    def render_data_or_redirect(message, data, user_data = {})
      if ['inAppBrowser', 'newWindow'].include?(omniauth_window_type)
        render_data(message, user_data.merge(data))
      elsif auth_origin_url
        redirect_to DeviseTokenAuth::Url.generate(auth_origin_url, data.merge(blank: true))
      else
        fallback_render data[:error] || 'An error occurred'
      end
    end

    # def clean_resource
    #   if auth_hash['provider'] == 'twitter'
    #     @resource.name = strip_emoji(@resource.name)
    #     @resource.nickname = strip_emoji(@resource.nickname)
    #   end
    # end
    # def strip_emoji(str)
    #   str.encode('SJIS', 'UTF-8', invalid: :replace, undef: :replace, replace: '').encode('UTF-8')
    # end
  end

 end 
