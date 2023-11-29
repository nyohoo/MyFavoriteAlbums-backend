class Api::V1::LikesController < ApplicationController
  before_action :authenticate_api_v1_user!
  def current_user_likes
    # TwitterAPI対応 暫定として、全てのユーザーを共通のユーザーにする
    current_api_v1_user = User.first

    likes = current_api_v1_user.likes.select("post_id").map(&:post_id)
    render json: { likes: likes }
  end

  def create
    # TwitterAPI対応 暫定として、全てのユーザーを共通のユーザーにする
    current_api_v1_user = User.first

    # すでにいいねしているかを確認
    if current_api_v1_user.likes.find_by(post_id: params[:id]).nil?
      # いいねしていない場合は、いいねを登録する   
      current_api_v1_user.likes.create(post_id: params[:id])
      render json: { message: 'いいねしました' }
    else
      render json: { message: 'すでにいいねしています' }
    end
  end

  def destroy
    # TwitterAPI対応 暫定として、全てのユーザーを共通のユーザーにする
    current_api_v1_user = User.first

    current_api_v1_user.likes.find_by(post_id: params[:id]).destroy
    render json: { message: 'いいねを取り消しました' }
  end
end
