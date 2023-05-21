class AddDefaultValueToHashTagInPosts < ActiveRecord::Migration[6.1]
  def change
    change_column :posts, :hash_tag, :string, default: "#私を構成する9枚", null: false
  end
end
