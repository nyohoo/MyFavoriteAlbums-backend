class Api::V1::PostsController < ApplicationController

  def create
    if api_v1_user_signed_in?
      albums = params[:albums]
      hash_tag = params[:hash_tag]

      logger.debug("hash_tag: #{params[:hash_tag]}")

      image_paths = []
      album_ids = []
      # 画像URLを配列に格納
      params[:albums].each do |album|
        image_paths.push(album["images"][0]["url"])
        album_ids.push(album["id"])
      end
      # 一意の画像パス生成のためuidを生成
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
      album_ids

      # Postモデルに新規投稿
      @post = Post.new(
        user_id: current_api_v1_user.id,
        hash_tag: hash_tag
      )
      binding.pry
      post = @post.image.attach(io: File.open(image_path), filename: File.basename(image_path), content_type: 'image/jpg')
      if post.image.attached?
        if post.save
          # Albumモデルに新規アルバムを作成
          album_ids.each do |album_id|
            Album.create(
              album_id: album_id,
              post_id: post.id
            )
          end
          render json: post
        else
          render json: { error: post.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error: "画像がありません" }, status: :unprocessable_entity
      end


    else
      render json: { error: "ログインしてください" }, status: :unauthorized
    end
  end

end
