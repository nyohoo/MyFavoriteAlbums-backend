class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable
  include DeviseTokenAuth::Concerns::User

  has_many :posts, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :likes, -> { order(created_at: :desc) }, dependent: :destroy

  has_many :bookmarks, -> { order(created_at: :desc) }, dependent: :destroy

  # DB保存前に暗号化
  before_save :encrypt_access_token

  # 返すユーザー情報のフィルタ
  def token_validation_response
    self.as_json(except: [
      :access_token,:access_token_secret, :created_at, :updated_at, :allow_password_change, :is_admin, :email
    ])
  end

  # access_tokenとaccess_token_secretを暗号化して保存する
  def encrypt_access_token
    key_len = ActiveSupport::MessageEncryptor.key_len
    secret = Rails.application.key_generator.generate_key('salt', key_len)
    crypt = ActiveSupport::MessageEncryptor.new(secret)
    self.access_token = crypt.encrypt_and_sign(access_token)
    self.access_token_secret = crypt.encrypt_and_sign(access_token_secret)
  end

  def format_bookmarks(bookmark_album_ids)
    albums = RSpotify::Album.find(bookmark_album_ids)
    dates = albums.map { |album| album.release_date.split('-')[0] if album.release_date }
    albums.zip(dates).map do |album, date|
      { 
        albumId: album.id,
        artistId: album.artists[0].id,
        albumName: album.name,
        albumArtist: album.artists[0].name,
        albumImagePath: album.images[0]['url'],
        albumReleaseDate: date 
      }
    end
  end
end
