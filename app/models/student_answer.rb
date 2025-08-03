class StudentAnswer < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :answer, presence: true
  validates :is_correct, inclusion: { in: [true, false] }

  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }

  def mark_as_correct!
    update!(is_correct: true)
  end

  def mark_as_incorrect!
    update!(is_correct: false)
  end
end
