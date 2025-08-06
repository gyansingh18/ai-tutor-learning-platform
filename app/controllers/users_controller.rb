class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @learning_progress = get_learning_progress
    Rails.logger.info "Learning progress type: #{@learning_progress.class}"
    Rails.logger.info "Learning progress content: #{@learning_progress.inspect}"
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
    # Temporary simplified version for debugging
    {
      total_chapters: 10,
      completed_chapters: 2,
      total_tasks: 5,
      accuracy_rate: 80,
      progress_data: []
    }
  end

  def get_recent_activities
    # Get recent student answers
    StudentAnswer.where(user: current_user)
                 .includes(:task)
                 .order(created_at: :desc)
                 .limit(10)
  end
end
