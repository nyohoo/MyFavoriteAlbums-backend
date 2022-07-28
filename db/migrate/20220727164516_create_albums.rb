class CreateAlbums < ActiveRecord::Migration[6.1]
  def change
    create_table :albums do |t|
      t.string :album_id, null: false
      t.timestamps
      t.references :post, null: false, foreign_key: true
    end
  end
end
