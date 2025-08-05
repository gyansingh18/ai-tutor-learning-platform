class AddFilePathToPdfMaterials < ActiveRecord::Migration[7.1]
  def change
    add_column :pdf_materials, :file_path, :string
  end
end
