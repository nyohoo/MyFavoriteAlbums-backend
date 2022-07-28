class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts do |t|
      t.string :hash_tag, null: false
      t.timestamps
      t.references :user, null: false, foreign_key: true
    end
  end
end
