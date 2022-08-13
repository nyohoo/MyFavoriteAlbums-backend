class Api::V1::UsersController < ApplicationController
  def show_users_post
    # kaminariで無限スクロール。userのpostsを取得。
    user = User.includes(:posts).find_by(uid: params[:uid])
    posts = user.posts.order("created_at DESC").page(params[:page]).per(5)
    pagenation = resources_with_pagination(posts)

    results = []

    # userに紐づくpostをフロントエンドで使用する形式に変換
    user.posts.each do |post|
      # post.created_atを年月日のフォーマットに変更
      created_at = post.created_at.strftime("%Y年%m月%d日")
      results << { post_uuid: post.uuid,
                  created_at: created_at,
                  hash_tag: post.hash_tag,
                  image_path: post.image.service_url }
    end

    render json: { user: user, posts: results, kaminari: pagenation }
  end

  def show_users_like
    user = User.includes(:posts, :likes).find_by(uid: params[:uid])
    posts = user.posts.order("created_at DESC").page(params[:page]).per(5)
    pagenation = resources_with_pagination(posts)

    results = []

    # userに紐づくlike_postsをフロントエンドで使用する形式に変換
    user.like_posts.each do |post|
      created_at = post.created_at.strftime("%Y年%m月%d日")
      results << { user: post.user, 
                  post_uuid: post.uuid,
                  created_at: created_at, 
                  hash_tag: post.hash_tag, 
                  image_path: post.image.service_url }
    end

    render json: { user: user, likes: results, kaminari: pagenation }
  end
end
