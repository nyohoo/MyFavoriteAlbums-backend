class Bookmark < ApplicationRecord
  belongs_to :user
  validates :spotify_album_id, presence: true
  validates :user_id, uniqueness: { scope: :spotify_album_id }
end
