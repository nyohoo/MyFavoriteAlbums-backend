class Api::V1::PostsController < ApplicationController
  include ApplicationHelper
  before_action :api_v1_user_signed_in?, only: [:create, :destroy]
  before_action :set_post, only: [:show, :destroy]

  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def index
    posts = paginate(Post.with_likes.newest_first, params[:page], 5)
    pagenation = resources_with_pagination(posts)

    results = []
    posts.each do |post|
      # post.created_atを年月日のフォーマットに変更
      created_at = post.created_at.strftime("%Y年%m月%d日")
      image_path = url_for(post.image)
      # フロントエンドで使用するデータを生成
      results << { id: post.id,
                  post_uuid: post.uuid,
                  created_at: created_at,
                  hash_tag: post.hash_tag, 
                  image_path: image_path, 
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
      user: @post.user,
      albums: albums,
      hash_tag: @post.hash_tag,
      dates: dates,
      id: @post.id,
      post_uuid: @post.uuid,
      likes: @post.likes,
      currentUserBookmarks: current_user_bookmarks
    }
  end

  def create
    image_processor = ImageProcessor.new(params[:image_paths])
    uuid = image_processor.process_images
    image_path = "./tmp/#{uuid}.jpg"
    params[:hash_tag] = '#私を構成する9枚' if params[:hash_tag].empty?

    # postインスタンスを生成
    tmp = Post.new(
      user_id: current_api_v1_user.id,
      hash_tag: params[:hash_tag],
      uuid: uuid
    )

    # S3に画像を保存
    post = tmp.image.attach(io: File.open(image_path),
                            filename: File.basename(image_path),
                            content_type: 'image/jpg')

    # S3保存用に一時保存した画像を削除
    File.delete(image_path)

    if post.record.save
      # postに紐づくalbumsデータを作成
      params[:album_ids].each do |album_id|
        Album.create(
          album_id: album_id,
          post_id: post.record.id
        )
      end
      render json: post.record.uuid
    else
      render json: { error: post.record.errors.full_messages }
    end
  end

  def destroy
    if @post.destroy
      render json: { message: "削除しました" }
    else
      render json: { error: @post.errors.full_messages }
    end
  end

  def random
    # ランダムに1つのPostを取得
    post = Post.order("RANDOM()").first

    if post
      created_at = post.created_at.strftime("%Y年%m月%d日")
      image_path = url_for(post.image)
      render json: { 
                    id: post.id,
                    post_uuid: post.uuid,
                    created_at: created_at,
                    hash_tag: post.hash_tag, 
                    image_path: image_path, 
                    user: post.user,
                    }
    else
      render json: { message: "No posts available" }
    end
  end

  private

  def set_post
    @post = Post.find_by(uuid: params[:uuid])
  end

  def current_user_bookmarks
    if api_v1_user_signed_in?
      current_api_v1_user.bookmarks.select("spotify_album_id").map(&:spotify_album_id)
    else
      []
    end
  end
end
