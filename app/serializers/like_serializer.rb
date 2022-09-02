class LikeSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :uuid, :created_at, :hash_tag, :image_path, :user

  def user
    { 
      id: object.post.user.id,
      uid: object.post.user.uid,
      name: object.post.user.name,
    }
  end

  def image_path
    url_for(object.post.images[0]['url'])
  end

  def created_at
    object.post.created_at.strftime("%Y年%m月%d日")
  end

  def hash_tag
    object.post.hash_tag
  end

  def uuid
    object.post.uuid
  end

  def id
    object.post.id
  end

end
