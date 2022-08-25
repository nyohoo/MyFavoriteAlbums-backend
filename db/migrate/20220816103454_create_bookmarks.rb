class CreateBookmarks < ActiveRecord::Migration[6.1]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      # spotify_album_idを保存するカラム
      t.string :spotify_album_id, null: false
      t.timestamps
    end
    add_index :bookmarks, [:user_id, :spotify_album_id], unique: true
  end
end
