class Api::V1::SongsController < ApplicationController
  require 'rspotify'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def search
    result = RSpotify::Album.search(params[:query], limit: 48, market: 'JP')
    render json: result
  end

  def add_search
    # 無限スクロールのため、params[:count]をoffsetにセットして検索している
    results = RSpotify::Album.search(params[:query], offset: params[:count], limit: 48, market: 'JP')
    if results.length > 0
      render json: results
    else
      render json: { no_result: "No results :(" }
    end
  end
end
