class AddUuidToPosts < ActiveRecord::Migration[6.1]
  def change
    add_column :posts, :uuid, :string, null: false, unique: true
  end
end
