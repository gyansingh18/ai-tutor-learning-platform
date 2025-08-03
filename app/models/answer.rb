class Answer < ApplicationRecord
  # Relationships
  belongs_to :question

  # Validations
  validates :content, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def display_content
    content.truncate(200)
  end
end
