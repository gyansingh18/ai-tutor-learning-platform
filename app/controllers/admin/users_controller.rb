class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @users = User.includes(:questions).order(created_at: :desc)
  end

  def show
    @user = User.find(params[:id])
    @questions = @user.questions.recent.includes(:chapter, :answer)
  end

  private

  def ensure_admin!
    unless current_user.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end
