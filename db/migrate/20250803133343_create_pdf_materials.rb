class CreatePdfMaterials < ActiveRecord::Migration[7.1]
  def change
    create_table :pdf_materials do |t|
      t.string :title
      t.references :chapter, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
