class Api::V1::SongsController < ApplicationController

  require 'rspotify'
  RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_SECRET_ID'])

  def search
    @musics = RSpotify::Track.search(params[:query], limit: 28, market: 'JP')
    render json: @musics
  end
end
