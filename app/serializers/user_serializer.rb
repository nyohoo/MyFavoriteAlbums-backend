class UserSerializer < ActiveModel::Serializer
  #url_forを利用するために、rails_helperをincludeする
  include Rails.application.routes.url_helpers

  attributes :id, :uuid, :created_at, :hash_tag, :image_path, :user

  # userの情報をaccess_tokenとaccess_token_secretを除いてattributesに追加
  def user
    { 
      id: object.user.id,
      uid: object.user.uid,
      name: object.user.name,
    }
  end

  # post.imageをurl_forで取得してattributesに追加
  def image_path
    url_for(object.image)
  end

  # post.created_atを年月日のフォーマットに整えてattributesに追加
  def created_at
    object.created_at.strftime("%Y年%m月%d日")
  end

end
