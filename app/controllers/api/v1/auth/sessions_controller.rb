class Api::V1::Auth::SessionsController < ApplicationController
  before_action :authenticate_api_v1_user!

  def index

    # TwitterAPI対応 暫定として、全てのユーザーを共通のユーザーにする
    current_api_v1_user = User.first

    if current_api_v1_user
      render json: { is_login: true, data: current_api_v1_user }
    else
      render json: { is_login: false, message: "ユーザーが存在しません" }
    end
  end
end