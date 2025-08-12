class Question < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :chapter
  has_one :answer, dependent: :destroy

  # Virtual attributes for form handling
  attr_accessor :grade_id, :subject_id

  # Validations
  validates :content, presence: true, length: { minimum: 3, maximum: 1000 }
  validates :chapter_id, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  # Methods
  def answered?
    answer.present?
  end

  def display_content
    content.truncate(100)
  end
end
