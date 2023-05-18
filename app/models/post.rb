class Post < ApplicationRecord
  belongs_to :user
  has_many :likes, dependent: :destroy
  has_many :albums, dependent: :destroy
  has_many :users, through: :likes
  has_one_attached :image

  scope :with_likes, -> { includes(:likes) }
  scope :newest_first, -> { order(created_at: :desc) }
end
