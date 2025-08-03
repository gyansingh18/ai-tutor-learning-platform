class CreateChapters < ActiveRecord::Migration[7.1]
  def change
    create_table :chapters do |t|
      t.string :name
      t.text :description
      t.references :subject, null: false, foreign_key: true

      t.timestamps
    end
  end
end
