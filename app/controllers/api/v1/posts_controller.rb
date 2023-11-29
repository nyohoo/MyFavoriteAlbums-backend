class Api::V1::PostsController < ApplicationController
  include ApplicationHelper
  before_action :set_post, only: [:show, :destroy]

  # TwitterAPI暫定対応 作成前のユーザー確認をスキップ
  # before_action :api_v1_user_signed_in?, only: [:create, :destroy]
  before_action :api_v1_user_signed_in?, only: [:destroy]

  def index
    posts = paginate(Post.with_likes.newest_first, params[:page], 5)
    pagenation = resources_with_pagination(posts)

    results = posts.map do |post|
      {
        id: post.id,
        post_uuid: post.uuid,
        created_at: post.formatted_created_at,
        hash_tag: post.hash_tag,
        image_path: post.image_path,
        user: post.user,
        likes: post.likes,
      }
    end

    response = { posts: results, kaminari: pagenation } 
    render json: response
  end

  def show
    album_ids = @post.albums.pluck(:album_id)
    albums = RSpotify::Album.find(album_ids)
    dates = albums.map { |album| album.release_date.split('-')[0] if album.release_date }

    render json: { 
      id: @post.id,
      post_uuid: @post.uuid,
      user: @post.user,
      albums: albums,
      hash_tag: @post.hash_tag,
      dates: dates,
      likes: @post.likes,
      currentUserBookmarks: current_user_bookmarks
    }
  end

  def create

    # TwitterAPI暫定対応 ユーザーを共有のアカウントにする
    current_api_v1_user = User.first

    # 画像を生成
    image_processor = ImageProcessor.new(post_params[:image_paths])
    uuid, image_path = image_processor.process_images

    # postインスタンスを生成
    post = Post.new(
      user_id: current_api_v1_user.id,
      hash_tag: params[:hash_tag],
      uuid: uuid
    )

    # S3に画像を保存
    post.upload_image_to_s3(image_path)

    if post.save
      # postに紐づくalbumsデータを作成
      post.create_albums(post_params[:album_ids])
      render json: post.uuid
    else
      render json: { error: post.record.errors.full_messages }
    end
  end

  def destroy
    if @post.destroy
      render json: { message: "削除しました" }
    else
      render json: { error: @post.errors.full_messages }, status: :error
    end
  end

  def random
    # ランダムに1つのPostを取得
    post = Post.order("RANDOM()").first

    if post
      render json: { 
                    id: post.id,
                    post_uuid: post.uuid,
                    created_at: post.formatted_created_at,
                    hash_tag: post.hash_tag, 
                    image_path: post.image_path, 
                    user: post.user,
                    }
    else
      render json: { message: "No posts available" }
    end
  end

  private
  def post_params
    params.permit(:hash_tag, image_paths: [], album_ids: [])
  end

  def set_post
    @post = Post.find_by!(uuid: params[:uuid])
  rescue ActiveRecord::RecordNotFound
    render json: { error: @post.errors.full_messages }, status: :not_found
  end

  def current_user_bookmarks
    if api_v1_user_signed_in?
      current_api_v1_user.bookmarks.select("spotify_album_id").map(&:spotify_album_id)
    else
      []
    end
  end
end
