# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable
  include DeviseTokenAuth::Concerns::User

  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :like_posts, through: :likes, source: :post

  before_save :encrypt_access_token

  # 返すユーザー情報のフィルタ
  def token_validation_response
    as_json(only: [:id, :uid, :name, :nickname, :image])
  end

  # access_tokenとaccess_token_secretを暗号化して保存する
  def encrypt_access_token
    key_len = ActiveSupport::MessageEncryptor.key_len
    secret = Rails.application.key_generator.generate_key('salt', key_len)
    crypt = ActiveSupport::MessageEncryptor.new(secret)
    self.access_token = crypt.encrypt_and_sign(access_token)
    self.access_token_secret = crypt.encrypt_and_sign(access_token_secret)
  end
end
