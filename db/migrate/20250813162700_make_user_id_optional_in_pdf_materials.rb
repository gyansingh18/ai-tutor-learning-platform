class MakeUserIdOptionalInPdfMaterials < ActiveRecord::Migration[7.1]
  def change
    change_column_null :pdf_materials, :user_id, true
  end
end
