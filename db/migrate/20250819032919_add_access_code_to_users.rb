class AddAccessCodeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :access_code, :string
  end
end
