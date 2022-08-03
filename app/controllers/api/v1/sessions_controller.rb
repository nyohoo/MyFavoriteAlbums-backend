class Api::V1::OAuth::SessionsController < ApplicationController
  before_action :authenticate_api_v1_user!

  def index
    if current_api_v1_user
      render json: { is_login: true, data: current_api_v1_user }
    else
      render json: { is_login: false, message: "ユーザーが存在しません" }
    end
  end
end