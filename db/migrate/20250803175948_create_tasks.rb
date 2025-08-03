class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :content
      t.integer :task_type
      t.integer :order
      t.references :chapter, null: false, foreign_key: true

      t.timestamps
    end
  end
end
