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

    # S3から画像URLを取得
    post_image = post.image_blob.service_url
    # Twitterに投稿するために画像URLをバイナリ形式で一時保存
    open("./tmp/#{post.uuid}", 'w+b') do |output|
      URI.open(post_image) do |data|
        output.puts(data.read)
        # 画像を一時保存したファイルパスを渡す
        post_image = output.path
      end
    end

    # ツイートの本文を作成
    text = "#{params[:text]}" + "\n" + "#{params[:url]}"

    # ツイートを投稿
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

  # 暗号を復元
  def access_token(post)
      crypt.decrypt_and_verify(post.user.access_token)
  end
  # 暗号を復元
  def access_token_secret(post)
    @access_token_secret = crypt.decrypt_and_verify(post.user.access_token_secret)
  end
end
