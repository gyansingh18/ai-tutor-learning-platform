class CreateVectorChunks < ActiveRecord::Migration[7.1]
  def change
    create_table :vector_chunks do |t|
      t.text :content
      t.text :embedding
      t.references :chapter, null: false, foreign_key: true
      t.references :pdf_material, null: false, foreign_key: true

      t.timestamps
    end
  end
end
