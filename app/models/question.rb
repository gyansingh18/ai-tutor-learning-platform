class Question < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :chapter
  has_one :answer, dependent: :destroy

  # Validations
  validates :content, presence: true, length: { minimum: 3, maximum: 1000 }

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
