class Api::V1::PostsController < ApplicationController
  include Rails.application.routes.url_helpers #url_forを利用するために、rails_helperをincludeする
  require 'rspotify'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def index
    posts = Post.order("created_at DESC").page(params[:page]).per(5)
    #pagenation_controllerにて定義したメソッドを利用し、ページネーション情報を取得
    pagenation = resources_with_pagination(posts)

    results = []
    posts.each do |post|
      # post.created_atを年月日のフォーマットに変更
      created_at = post.created_at.strftime("%Y年%m月%d日")
      # フロントエンドで使用するデータを生成
      results << { post_uuid: post.uuid,
                  created_at: created_at,
                  hash_tag: post.hash_tag, 
                  image_path: post.image.service_url, 
                  user: post.user }
    end
    
    response = { posts: results, kaminari: pagenation } 
    render json: response
  end

  def show
    # uuidを元にpostを取得
    post = Post.find_by(uuid: params[:uuid])

    # postに紐づくalbumを取得
    album_ids = post.albums.pluck(:album_id)
    albums = RSpotify::Album.find(album_ids)

    # リリースデータを年のみのフォーマットに整える
    dates = []
    albums.each do |album|
      if album.release_date.present?
        dates << album.release_date.split('-')[0]
      else
        dates << ""
      end
    end

    render json: { user: post.user, albums: albums, hash_tag: post.hash_tag, dates: dates }
  end

  def create
    if api_v1_user_signed_in?
      # 一意の画像パス生成のためuidを生成
      uuid = SecureRandom.hex(8)

      # 9枚のジャケットイメージを3×3のタイルに加工し、tmpディレクトリに一時保存
      MiniMagick::Tool::Montage.new do |montage|
        params[:image_paths].each { |image| montage << image }
        montage.geometry "640x640+0+0"
        montage.tile "3x3"
        montage << "tmp/images/#{uuid}.jpg"
      end

      # tmpディレクト内の画像パスの取得
      image_path = "tmp/images/#{uuid}.jpg"

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

      # tmpディレクトリ内の画像を削除
      File.delete(image_path)

      # issue:imageが保存されているか確認する処理を追加

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
        render json: { error: post.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "ログインしてください" }, status: :unauthorized
    end
  end
end
