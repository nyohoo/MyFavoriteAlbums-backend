class AddAccessTokenColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :access_token, :string, null: false
    add_column :users, :access_token_secret, :string, null: false
  end
end
