class Api::V1::PostsController < ApplicationController
  before_action :api_v1_user_signed_in?, only: [:create, :destroy]
  include Rails.application.routes.url_helpers #url_forを利用するために、rails_helperをincludeする
  require 'rspotify'
  require 'open-uri'

  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def index
    posts = Post.order("created_at DESC").page(params[:page]).per(5)
    #pagenation_controllerにて定義したメソッドを利用し、ページネーション情報を取得
    pagenation = resources_with_pagination(posts)

    results = []
    posts.each do |post|
      # post.created_atを年月日のフォーマットに変更
      created_at = post.created_at.strftime("%Y年%m月%d日")
      image_path = url_for(post.image)
      # フロントエンドで使用するデータを生成
      results << { post_uuid: post.uuid,
                  created_at: created_at,
                  hash_tag: post.hash_tag, 
                  image_path: image_path, 
                  user: post.user }
    end
    
    response = { posts: results, kaminari: pagenation } 
    render json: response
  end

  def show
    # ログイン中の場合は、ログイン中のユーザーのブックマーク情報を取得する
    if api_v1_user_signed_in?
      current_user_bookmarks = current_api_v1_user.bookmarks.select("spotify_album_id").map(&:spotify_album_id)
    else
      bookamrks = nil
    end

    # uuidを元にpostを取得
    post = Post.find_by(uuid: params[:uuid])
    # postに紐づくalbumを取得
    album_ids = post.albums.pluck(:album_id)
    # Album.findに配列でidを渡すと一気に取得可能
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

    render json: { user: post.user,
                  albums: albums,
                  hash_tag: post.hash_tag,
                  dates: dates,
                  id: post.id,
                  post_uuid: post.uuid,
                  likes: post.likes,
                  currentUserBookmarks: current_user_bookmarks }
  end

  def create
    # 一時保存した画像を格納する空の配列を生成
    tmp_images = []

    # heroku環境上では、MiniMagickを使用して画像加工するためにURLを直接開くと
    # "attempt to perform an operation not allowed by the security policy `HTTPS'"のエラーが発生するため、
    # 画像を一時的に保存する必要がある
    params[:image_paths].each do |image_path|
    
      # ファイル名を取得
      filename = File.basename(image_path)
    
      # filenameで設定したファイル名で画像のバイナリファイルを作成
      open("./tmp/#{filename}", 'w+b') do |output|
        URI.open(image_path) do |data|
          output.puts(data.read)
        
          # 作成したバイナリファイルを配列に格納
          tmp_images << output.path
        end
      end
    end
  
    # 一意の値をtmp画像パスおよびpostのuuidに使用する
    uuid = SecureRandom.hex(8)
    # 9枚のジャケットイメージを3×3のタイルに加工し、tmp_imagesフォルダに一時保存
    MiniMagick::Tool::Montage.new do |montage|
      tmp_images.each { |image| montage << image }
      montage.geometry "640x640+0+0"
      montage.tile "3x3"
      montage << "./tmp/#{uuid}.jpg"
    end
  
    # tmpディレクト内の画像パスの取得
    image_path = "./tmp/#{uuid}.jpg"
    # params[:hash_tag]が空の場合は、ハッシュタグを生成する
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
    # tmp_imagesディレクト内の画像を削除
    tmp_images.each do |image|
      File.delete(image)
    end
  
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
      render json: { error: post.record.errors.full_messages }
    end
  end

  def destroy
    post = Post.find_by(uuid: params[:uuid])
    if post.destroy
      render json: { message: "削除しました" }
    else
      render json: { error: post.errors.full_messages }
    end
  end
end
