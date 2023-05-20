class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show_user, :show_user_posts, :show_user_likes, :show_user_bookmarks]

  def show_user
    render json: { user: @user }
  end

  def show_user_posts
    user_posts = @user.posts.order("created_at DESC").page(params[:page]).per(5)
    render json: user_posts, each_serializer: UserSerializer
  end

  def show_user_likes
    like_posts = @user.likes.page(params[:page]).per(5)
    render json: like_posts, each_serializer: LikeSerializer
  end

  def show_user_bookmarks
    bookmark_album_ids = @user.bookmarks.select("spotify_album_id").page(params[:page]).per(10).map(&:spotify_album_id)

    if bookmark_album_ids.present?
      results = @user.format_bookmarks(bookmark_album_ids) # Moved to User model
      render json: { results: results }
    else 
      render json: { results: [] }
    end
  end

  private

  def set_user
    @user = User.find_by!(uid: params[:uid])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end
end
