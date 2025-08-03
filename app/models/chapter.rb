class Chapter < ApplicationRecord
  # Relationships
  belongs_to :subject
  has_many :questions, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :pdf_materials, dependent: :destroy
  has_many :vector_chunks, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :name, uniqueness: { scope: :subject_id }

  # Scopes
  scope :ordered, -> { order(:name) }

  # Methods
  def display_name
    "#{subject.grade.name} - #{subject.name} - #{name}"
  end

  def grade
    subject.grade
  end

  def grade_name
    subject.grade.name
  end

  def subject_name
    subject.name
  end

  def first_task
    tasks.ordered.first
  end

  def last_task
    tasks.ordered.last
  end

  def total_tasks
    tasks.count
  end
end
