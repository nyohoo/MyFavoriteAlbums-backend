class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts do |t|
      t.text :image, null: false
      t.string :hash_tags, null: false
      t.timestamps
      t.references :user, null: false, foreign_key: true
    end
  end
end
