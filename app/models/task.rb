class Task < ApplicationRecord
  belongs_to :chapter
  has_many :student_answers, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true
  validates :task_type, presence: true
  validates :order, presence: true, numericality: { only_integer: true, greater_than: 0 }

  enum task_type: {
    multiple_choice: 0,
    fill_in_blank: 1,
    coding: 2,
    short_answer: 3,
    true_false: 4
  }

  scope :ordered, -> { order(:order) }

  def next_task
    chapter.tasks.where('"order" > ?', order).ordered.first
  end

  def previous_task
    chapter.tasks.where('"order" < ?', order).ordered.last
  end

  def is_first?
    order == 1
  end

  def is_last?
    order == chapter.tasks.maximum(:order)
  end
end
