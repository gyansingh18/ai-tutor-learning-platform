class PdfMaterial < ApplicationRecord
  # Relationships
  belongs_to :chapter
  belongs_to :user, optional: true  # Made optional for bulk imports
  has_many :vector_chunks, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :file_path, presence: true
  validate :file_path_format

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  # Methods
  def file_path_format
    return unless file_path.present?

    unless file_path.end_with?('.pdf')
      errors.add(:file_path, 'must be a PDF file path')
    end
  end

  def file_name
    File.basename(file_path) if file_path.present?
  end

  def file_size
    # This will be set when creating the record
    super
  end

  def display_title
    title.presence || file_name
  end
end
