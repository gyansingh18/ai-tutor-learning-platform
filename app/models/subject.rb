class Subject < ApplicationRecord
  # Relationships
  belongs_to :grade
  has_many :chapters, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :name, uniqueness: { scope: :grade_id }

  # Scopes
  scope :ordered, -> { order(:name) }

  # Methods
  def display_name
    "#{grade.name} - #{name}"
  end
end
