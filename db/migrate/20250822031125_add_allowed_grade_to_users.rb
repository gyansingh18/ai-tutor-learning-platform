class AddAllowedGradeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :allowed_grade, :string
  end
end
