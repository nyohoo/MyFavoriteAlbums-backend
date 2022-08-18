class Api::V1::UsersController < ApplicationController
  include Rails.application.routes.url_helpers #url_forを利用するために、rails_helperをincludeする
  require 'rspotify'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])
  
  def show_user
    user = User.find_by(uid: params[:uid])
    render json: { user: user }
  end

  def show_user_posts
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

  def show_user_likes
    # kaminariで無限スクロール。userのlikesを取得。nullの場合は空の配列を返す。
    like_posts = User.find_by(uid: params[:uid]).likes.page(params[:page]).per(5)
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

  def show_user_bookmarks
    if api_v1_user_signed_in?
      current_user_bookmarks = current_api_v1_user.bookmarks.select("spotify_album_id").map(&:spotify_album_id)
    else
      current_user_bookmarks = nil
    end

    # kaminariで無限スクロール。userのlikesを取得。nullの場合は空の配列を返す。
    bookmarks = User.find_by(uid: params[:uid]).bookmarks.select("spotify_album_id").page(params[:page]).per(10).map(&:spotify_album_id)
    if bookmarks.present?
      results = []

      albums = RSpotify::Album.find(bookmarks)
      # リリースデータを年のみのフォーマットに整える
      dates = []
      albums.each do |album|
        if album.release_date.present?
          dates << album.release_date.split('-')[0]
        else
          dates << ""
        end
      end
      # albumsとdatesを結合して、フロントエンドで使用する形式に変換

      albums.zip(dates).each do |album, date|
        results << { albumId: album.id,
                    artistId: album.artists[0].id,
                    albumName: album.name,
                    albumArtist: album.artists[0].name,
                    albumImagePath: album.images[0]['url'],
                    albumReleaseDate: date }
      end
      render json: { bookmarks: results, currentUserBookmarks: current_user_bookmarks }  

    else 
      render json: { bookmarks: [] }
    end
  end
end
