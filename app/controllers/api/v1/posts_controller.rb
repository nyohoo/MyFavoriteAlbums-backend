class Api::V1::PostsController < ApplicationController
  include Rails.application.routes.url_helpers

  def show
    @post = Post.find(params[:id])
    render json: @post, include: [:user, :likes, :albums, :image]
  end

  def create
    if api_v1_user_signed_in?
      # 一意の画像パス生成のためuidを生成
      uid = SecureRandom.hex(3)
      # 画像を3×3のタイルに加工
      MiniMagick::Tool::Montage.new do |montage|
        params[:image_paths].each { |image| montage << image }
        montage.geometry "640x640+0+0"
        montage.tile "3x3"
        montage << "tmp/images/#{uid}.jpg"
      end
      # 画像パスの取得
      image_path = "tmp/images/#{uid}.jpg"
      # Postモデルに新規投稿
      tmp = Post.new(
        user_id: current_api_v1_user.id,
        hash_tag: params[:hash_tag]
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
        render json: post.record.id
      else
        render json: { error: post.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "ログインしてください" }, status: :unauthorized
    end
  end
end
