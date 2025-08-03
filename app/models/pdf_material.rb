class PdfMaterial < ApplicationRecord
  # Relationships
  belongs_to :chapter
  belongs_to :user
  has_many :vector_chunks, dependent: :destroy
  has_one_attached :pdf_file

  # Validations
  validates :title, presence: true
  validates :pdf_file, presence: true
  validate :pdf_file_type

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  # Methods
  def pdf_file_type
    return unless pdf_file.attached?

    unless pdf_file.content_type.in?(%w[application/pdf])
      errors.add(:pdf_file, 'must be a PDF file')
    end
  end

  def file_name
    pdf_file.filename.to_s if pdf_file.attached?
  end

  def file_size
    pdf_file.byte_size if pdf_file.attached?
  end

  def display_title
    title.presence || file_name
  end
end
