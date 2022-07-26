class Api::V1::SongsController < ApplicationController

  require 'rspotify'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def search
    result = RSpotify::Album.search(params[:query], limit: 48, market: 'JP')
    render json: result
  end

  def post_albums
    albums = params[:albums]
    hash_tag = params[:hash_tag]

    # 画像を取得する
    @album_images = []
    @album_ids = []
    albums.each do |album|
      @album_images.push(album["images"][0]["url"])
      @album_ids.push(album["id"])
    end

    logger.debug("------------@album_images--------------------")
    logger.debug(@album_images)
    logger.debug("---------------------------------------------")

    logger.debug("------------@album_ids-----------------------")
    logger.debug(@album_ids)
    logger.debug("---------------------------------------------")

    @albums = RSpotify::Album.find(@album_ids)
    logger.debug("------------@albumsの中身！！---------------")
    logger.debug(@albums)
    logger.debug("--------------------------------------------")

      @albums.each do |album|
        @album = album
        logger.debug("------------Spotifyで検索してみる------------")
        logger.debug(@album)
        logger.debug("-------------------------------------------")
      end

    logger.debug("------------CurrentUser---------------")
    logger.debug(current_api_v1_user.id)

  render json: @albums

  end

  def get_albums

  end

end
