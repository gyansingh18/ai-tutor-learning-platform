class VectorChunk < ApplicationRecord
  # Relationships
  belongs_to :chapter
  belongs_to :pdf_material

  # Validations
  validates :content, presence: true
  validates :embedding, presence: true

  # Scopes
  scope :by_chapter, ->(chapter) { where(chapter: chapter) }
  scope :by_pdf_material, ->(pdf_material) { where(pdf_material: pdf_material) }

  # Methods
  def embedding_array
    JSON.parse(embedding) if embedding.present?
  rescue JSON::ParserError
    []
  end

  def set_embedding(array)
    self.embedding = array.to_json
  end

  def content_preview
    content.truncate(150)
  end
end
