class Api::V1::UsersController < ApplicationController
  require 'rspotify'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])
  
  def show_user
    user = User.find_by(uid: params[:uid])
    render json: { user: user }
  end

  def show_user_posts
    # params[:uid]を元にuserの情報を取得し、userに紐づくpostsをcreated_atで降順に並び替えて5件ずつ取得
    user_posts = User.find_by(uid: params[:uid]).posts.order("created_at DESC").page(params[:page]).per(5)
    render json: user_posts, each_serializer: UserSerializer
  end

  def show_user_likes
    # kaminariで無限スクロール。userのlikesを取得。nullの場合は空の配列を返す。
    like_posts = User.find_by(uid: params[:uid]).likes.page(params[:page]).per(5)

    render json: like_posts, each_serializer: LikeSerializer
  end

  def show_user_bookmarks
    # ログイン中の場合は、ログイン中のユーザーのブックマーク情報を取得する
    if api_v1_user_signed_in?
      current_user_bookmarks = current_api_v1_user.bookmarks.select("spotify_album_id").map(&:spotify_album_id)
    else
      current_user_bookmarks = nil
    end

    # kaminariで無限スクロール。userのbookmarksを取得。nullの場合は空の配列を返す。
    bookmark_album_ids = User.find_by(uid: params[:uid]).bookmarks.select("spotify_album_id").page(params[:page]).per(10).map(&:spotify_album_id)

    if bookmark_album_ids.present?
      albums = RSpotify::Album.find(bookmark_album_ids)
      results = []
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
      render json: results, currentUserBookmarks: current_user_bookmarks

    else 
      render json: { bookmarks: [] }
    end
  end
end
