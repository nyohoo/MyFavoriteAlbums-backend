class Api::V1::UsersController < ApplicationController
  def show
    # userをuidでpostsを含めて取得
    user = User.includes(:posts).find_by(uid: params[:uid])
    
    posts = []
    # userに紐づくpostごとにフロントエンドで使用するデータを生成
    user.posts.each do |post|
      # post.created_atを年月日のフォーマットに変更
      created_at = post.created_at.strftime("%Y年%m月%d日")
      posts << { post_uuid: post.uuid, created_at: created_at, hash_tag: post.hash_tag, image_path: post.image.service_url }
    end

    render json: { user: user, posts: posts }
  end
end
