class Api::V1::SongsController < ApplicationController

  require 'rspotify'
  require 'mini_magick'
  require 'securerandom'

  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def search
    result = RSpotify::Album.search(params[:query], limit: 48, market: 'JP')
    render json: result
  end

  def post_albums
    if !current_api_v1_user.id.blank?

      albums = params[:albums]
      hash_tag = params[:hash_tag]

      # 画像を取得する
      image_paths = []
      album_ids = []
      albums.each do |album|
        image_paths.push(album["images"][0]["url"])
        album_ids.push(album["id"])
      end

      # 画像パス生成のためuidを生成
      uid = SecureRandom.hex(3)

      # 画像を3×3のタイルに加工
      MiniMagick::Tool::Montage.new do |montage|
        image_paths.each { |image| montage << image }
        montage.geometry "640x640+0+0"
        montage.tile "3x3"
        montage << "tmp/images/#{uid}.jpg"
      end

      # 画像パスの取得
      image_path = "tmp/images/#{uid}.jpg"
      render json: album_ids
    else
      render json: { error: "ログインしてください" }, status: :unauthorized
    end
  end

  def get_albums
    
  end
end
