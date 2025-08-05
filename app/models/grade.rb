class Grade < ApplicationRecord
  # Relationships
  has_many :subjects, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  # Scopes
  scope :ordered, -> { order(:name) }

  # Methods
  def display_name
    name
  end
end
