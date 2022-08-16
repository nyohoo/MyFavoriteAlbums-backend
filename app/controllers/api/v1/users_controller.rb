class Api::V1::UsersController < ApplicationController
  def show_user
    user = User.find_by(uid: params[:uid])
    render json: { user: user }
  end

  def show_users_post
    # params[:uid]を元にuserの情報を取得し、userに紐づくpostsをcreated_atで降順に並び替えて5件ずつ取得
    posts = User.find_by(uid: params[:uid]).posts.order("created_at DESC").page(params[:page]).per(5)
    results = []

    # userに紐づくpostをフロントエンドで使用する形式に変換
    posts.each do |post|
      # post.created_atを年月日のフォーマットに変更
      created_at = post.created_at.strftime("%Y年%m月%d日")
      image_path = url_for(post.image)
      results << { post_uuid: post.uuid,
                  created_at: created_at,
                  hash_tag: post.hash_tag,
                  image_path: image_path }
    end

    render json: { posts: results }
  end

  def show_users_like
    # kaminariで無限スクロール。userのlikesを取得。nullの場合は空の配列を返す。
    like_posts = User.find_by(uid: params[:uid]).likes.order("created_at DESC").page(params[:page]).per(5)
    results = []

    # userに紐づくlike_postsをフロントエンドで使用する形式に変換
    like_posts.each do |like_post|
      created_at = like_post.post.created_at.strftime("%Y年%m月%d日")
      image_path = url_for(like_post.post.image)
      results << { user: like_post.post.user, 
                  post_uuid: like_post.post.uuid,
                  created_at: created_at, 
                  hash_tag: like_post.post.hash_tag, 
                  image_path: image_path }
    end

    render json: { likes: results }
  end
end
