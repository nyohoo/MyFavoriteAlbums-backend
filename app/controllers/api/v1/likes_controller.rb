class Api::V1::LikesController < ApplicationController
  before_action :authenticate_api_v1_user!
  def create
    current_api_v1_user.likes.create(post_id: params[:post_id])
    head :created
  end

  def destroy
    current_api_v1_user.likes.find_by(post_id: params[:post_id]).destroy
  end
end
