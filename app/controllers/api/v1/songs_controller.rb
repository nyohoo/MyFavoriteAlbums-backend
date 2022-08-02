class Api::V1::SongsController < ApplicationController
  require 'rspotify'
  require 'mini_magick'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def search
    result = RSpotify::Album.search(params[:query], limit: 48, market: 'JP')
    render json: result
  end

  def add_search
    results = RSpotify::Album.search(params[:query], offset: params[:count],limit: 48, market: 'JP')
    if results.length > 0
      render json: results
    else
      render json: no_result
    end
  end
end
