class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @grades = Grade.all
    @learning_stats = get_learning_stats if user_signed_in?
    @resume_chapter = get_resume_chapter if user_signed_in?
  end

  private

  def get_learning_stats
    return nil unless user_signed_in?

    # Get user's learning progress
    chapters_with_progress = Chapter.joins(tasks: :student_answers)
                                   .where(student_answers: { user: current_user })
                                   .distinct

    total_chapters_started = chapters_with_progress.count
    completed_chapters = chapters_with_progress.select do |chapter|
      total_tasks = chapter.tasks.count
      completed_tasks = chapter.tasks.joins(:student_answers)
                               .where(student_answers: { user: current_user })
                               .distinct.count
      total_tasks > 0 && completed_tasks >= total_tasks
    end.count

    total_tasks_completed = StudentAnswer.where(user: current_user).count
    correct_answers = StudentAnswer.where(user: current_user, is_correct: true).count
    accuracy_rate = total_tasks_completed > 0 ? (correct_answers.to_f / total_tasks_completed * 100).round : 0

    {
      total_chapters_started: total_chapters_started,
      completed_chapters: completed_chapters,
      total_tasks_completed: total_tasks_completed,
      correct_answers: correct_answers,
      accuracy_rate: accuracy_rate
    }
  end

  def get_resume_chapter
    return nil unless user_signed_in?

    # Find the most recent chapter with incomplete progress
    incomplete_chapters = Chapter.joins(tasks: :student_answers)
                                .where(student_answers: { user: current_user })
                                .distinct
                                .select do |chapter|
      total_tasks = chapter.tasks.count
      completed_tasks = chapter.tasks.joins(:student_answers)
                               .where(student_answers: { user: current_user })
                               .distinct.count
      total_tasks > 0 && completed_tasks < total_tasks
    end

    # Return the most recent one (by latest student answer)
    if incomplete_chapters.any?
      latest_answer = StudentAnswer.where(user: current_user, task: incomplete_chapters.flat_map(&:tasks))
                                  .order(created_at: :desc)
                                  .first
      
      if latest_answer
        latest_answer.task.chapter
      else
        incomplete_chapters.first
      end
    else
      nil
    end
  end
end
