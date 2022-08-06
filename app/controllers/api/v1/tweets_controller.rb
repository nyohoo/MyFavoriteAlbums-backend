class Api::V1::TweetsController < ApplicationController
  require 'twitter'
  require 'open-uri'
  def create
    post = Post.find_by(uuid: params[:post_uuid])

    # ツイートを投稿するためにユーザーのアクセストークンを設定したclientを生成
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_API_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_API_CONSUMER_SECRET']
      config.access_token        = access_token(post)
      config.access_token_secret = access_token_secret(post)
    end

    post_image = post.image_blob.service_url
    # バイナリ形式で一時保存してから投稿する
    open("./tmp/#{post.uuid}", 'w+b') do |output|
      URI.open(post_image) do |data|
        output.puts(data.read)
        # 画像を一時保存したファイルパスを渡す
        post_image = output.path
      end
    end
    
    # JPG形式に保存する処理、不要かも？
    # file = File.open("./tmp/#{post.uuid}.jpg", 'wb') do |f|
    #   f.write(post_image)
    # end

    # file = URI.open("./tmp/#{post.uuid}.jpg", 'wb') do |f|
    #   f.write(post_image)
    # end

    # ツイートの本文を作成
    text = "#{params[:text]}" +  "\n" + "#{post.hash_tag}" + "\n" +  "\n" + "\n" + "詳細はこちら" + "\n" "#{params[:url]}"

    # Twitterの推奨する画像アップロード方法ではうまくいかないので保留
    # バイナリ形式でダウンロード
    # post_image = post.image_blob.download
    # base_file = Base64.decode64(post.image.service_url)
    # file = post_image
    # init_request = Twitter::REST::Request.new(client, :post, "https://upload.twitter.com/1.1/media/upload.json", command: 'INIT', total_bytes: base_file.size, media_type: "image/jpeg").perform
    # media_id = init_request[:media_id]
    # Twitter::REST::Request.new(client, :post, "https://upload.twitter.com/1.1/media/upload.json", command: 'APPEND', media_id: media_id, media: file, segment_index: 0).perform
    # Twitter::REST::Request.new(client, :post, "https://upload.twitter.com/1.1/media/upload.json", command: 'STATUS', media_id: media_id, media: file).perform
    # Twitter::REST::Request.new(client, :post, "https://upload.twitter.com/1.1/media/upload.json", command: 'FINALIZE',media_id: media_id).perform
    # テキスト・URL・画像を投稿
    # Twitter::REST::Request.new(client, :post, "https://api.twitter.com/1.1/statuses/update.json", status: params[:text], attachment_url: params[:url], media_ids: media_id).perform

    if client.update_with_media(text, post_image)
      render json: { message: "ツイートが完了しました" }
    else
      error_json = {
        'code' => 422,
        'title' => '登録内容が適切ではありません',
        'detail' => '登録内容を確認してください',
        'messages' => update_client.errors.full_messages
      }
      render json: { error: error_json }, status: :unprocessable_entity
    end
  end

  private
  def crypt
    key_len = ActiveSupport::MessageEncryptor.key_len
    secret = Rails.application.key_generator.generate_key('salt', key_len)
    ActiveSupport::MessageEncryptor.new(secret)
  end

  def access_token(post)
      crypt.decrypt_and_verify(post.user.access_token)
  end

  def access_token_secret(post)
    @access_token_secret = crypt.decrypt_and_verify(post.user.access_token_secret)
  end
end
