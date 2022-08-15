class Api::V1::LikesController < ApplicationController
  before_action :authenticate_api_v1_user!
  def create
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
    current_api_v1_user.likes.find_by(post_id: params[:id]).destroy
    render json: { message: 'いいねを取り消しました' }
  end
end
