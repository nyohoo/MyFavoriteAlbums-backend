class Post < ApplicationRecord
  belongs_to :user
  has_many :likes, dependent: :destroy
  has_many :albums, dependent: :destroy
  has_many :users, through: :likes
  has_one_attached :image

end
