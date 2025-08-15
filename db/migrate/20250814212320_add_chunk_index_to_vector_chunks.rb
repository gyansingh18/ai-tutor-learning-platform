class AddChunkIndexToVectorChunks < ActiveRecord::Migration[7.1]
  def change
    add_column :vector_chunks, :chunk_index, :integer
  end
end
