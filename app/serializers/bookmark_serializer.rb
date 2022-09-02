class BookmarkSerializer < ActiveModel::Serializer
  # SpotifyApiから取得したデータをActiveModel::Serializerで整形する

  attributes :album_id
  attributes :artist_id
  attributes :album_name
  attributes :album_artist
  attributes :album_image_path
  attributes :album_release_date
  
  def album_id
    object.id
  end

  def artist_id
    object.artists[0].id
  end

  def album_name
    object.album.name
  end

  def album_artist
    object.artists[0].name
  end

  def album_image_path
    object.images[0]['url']
  end

  def album_release_date
    if object.release_date.present?
      object.release_date.split('-')[0]
    else
      ""
    end
  end

end
