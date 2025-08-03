class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @learning_progress = get_learning_progress
    @recent_activities = get_recent_activities
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, notice: 'Profile updated successfully.'
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end

  def get_learning_progress
    # Get all chapters with tasks that the user has started
    chapters_with_progress = Chapter.joins(tasks: :student_answers)
                                   .where(student_answers: { user: current_user })
                                   .distinct

    progress_data = []

    chapters_with_progress.each do |chapter|
      total_tasks = chapter.tasks.count
      completed_tasks = chapter.tasks.joins(:student_answers)
                               .where(student_answers: { user: current_user })
                               .distinct.count
      correct_answers = chapter.tasks.joins(:student_answers)
                               .where(student_answers: { user: current_user, is_correct: true })
                               .distinct.count

      progress_percentage = total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round : 0
      score_percentage = total_tasks > 0 ? (correct_answers.to_f / total_tasks * 100).round : 0

      progress_data << {
        chapter: chapter,
        total_tasks: total_tasks,
        completed_tasks: completed_tasks,
        correct_answers: correct_answers,
        progress_percentage: progress_percentage,
        score_percentage: score_percentage,
        is_completed: completed_tasks >= total_tasks && total_tasks > 0
      }
    end

    progress_data.sort_by { |data| data[:chapter].display_name }
  end

  def get_recent_activities
    # Get recent student answers
    StudentAnswer.where(user: current_user)
                 .includes(:task)
                 .order(created_at: :desc)
                 .limit(10)
  end
end
