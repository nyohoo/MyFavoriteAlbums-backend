class Api::V1::BookmarksController < ApplicationController
  before_action :authenticate_api_v1_user!
  def current_user_bookmarks
    # TwitterAPI対応 暫定として、全てのユーザーを共通のユーザーにする
    current_api_v1_user = User.first

    current_user_bookmarks = current_api_v1_user.bookmarks.select("spotify_album_id").map(&:spotify_album_id)
    render json: { bookmarks: current_user_bookmarks }
  end

  def create
    # TwitterAPI対応 暫定として、全てのユーザーを共通のユーザーにする
    current_api_v1_user = User.first

    current_api_v1_user.bookmarks.create(spotify_album_id: params[:id])
    render json: { message: 'ブックマークに登録しました' }
  end

  def destroy
    # TwitterAPI対応 暫定として、全てのユーザーを共通のユーザーにする
    current_api_v1_user = User.first

    current_api_v1_user.bookmarks.find_by(spotify_album_id: params[:id]).destroy
    render json: { message: 'ブックマークを取り消しました' }
  end
end
