class CreateStudentAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :student_answers do |t|
      t.text :answer
      t.boolean :is_correct
      t.references :task, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
