class Api::V1::PostsController < ApplicationController
  include Rails.application.routes.url_helpers
  require 'rspotify'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def show
    post = Post.find_by(uuid: params[:uuid])
    # image = post.image.service_url
    album_ids = post.albums.pluck(:album_id)
    albums = RSpotify::Album.find(album_ids)
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
      # 画像を3×3のタイルに加工
      MiniMagick::Tool::Montage.new do |montage|
        params[:image_paths].each { |image| montage << image }
        montage.geometry "640x640+0+0"
        montage.tile "3x3"
        montage << "tmp/images/#{uuid}.jpg"
      end
      # 画像パスの取得
      image_path = "tmp/images/#{uuid}.jpg"
      # Postモデルに新規投稿
      tmp = Post.new(
        user_id: current_api_v1_user.id,
        hash_tag: params[:hash_tag],
        uuid: uuid
      )
      post = tmp.image.attach(io: File.open(image_path),
                              filename: File.basename(image_path),
                              content_type: 'image/jpg')
      # tmpディレクトリ内の画像を削除
      File.delete(image_path)
      # issue:imageが保存されているか確認する処理を追加
      if post.record.save
        # Albumモデルに新規アルバムを作成
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
