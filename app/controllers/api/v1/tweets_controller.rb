class Api::V1::TweetsController < ApplicationController
  require 'twitter'
  def create
    post = Post.find_by(params[:post_uuid])

    # ツイートを投稿するためにユーザーのアクセストークンを設定したclientを生成
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_API_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_API_CONSUMER_SECRET']
      config.access_token        = access_token(post)
      config.access_token_secret = access_token_secret(post)
    end

    # S3のURLを取得
    post_image = post.image.service_url
    # S3のURLでは長すぎるので、postのuuidを使って短くして
    # バイナリ形式で一時保存してから投稿する
    open("./tmp/#{post.uuid}", 'w+b') do |output|
      URI.open(post_image) do |data|
        output.puts(data.read)
        # 画像を一時保存したファイルパスを渡す
        post_image = output.path
      end
    end
    # ツイッターにpost_imageの画像と、params[:text]の内容を含めてツイートする
    client.update_with_media(params[:text], open(post_image))

    render json: { message: "ツイートが完了しました" }
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
