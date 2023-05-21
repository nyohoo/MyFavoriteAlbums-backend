class Post < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :user
  has_many :likes, dependent: :destroy
  has_many :albums, dependent: :destroy
  has_many :users, through: :likes
  has_one_attached :image

  scope :with_likes, -> { includes(:likes) }
  scope :newest_first, -> { order(created_at: :desc) }

  def create_albums(album_ids)
    album_ids.each do |album_id|
      albums.create(album_id: album_id)
    end
  end

  def formatted_created_at
    created_at.strftime("%Y年%m月%d日")
  end

  def image_path
    url_for(image)
  end

  def upload_image_to_s3(path)
    # S3へのアップロードのロジック
    image.attach(
      io: File.open(path),
      filename: File.basename(path),
      content_type: 'image/jpg'
    )
    # S3保存用に一時保存した画像を削除
    File.delete(path)
  end
end
