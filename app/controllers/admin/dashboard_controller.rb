class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @total_users = User.count
    @total_questions = Question.count
    @total_pdf_materials = PdfMaterial.count
    @total_vector_chunks = VectorChunk.count

    @recent_questions = Question.recent.limit(5).includes(:user, :chapter)
    @recent_pdf_materials = PdfMaterial.recent.limit(5).includes(:user, :chapter)

    @users_by_role = User.group(:role).count
  end

  private

  def ensure_admin!
    unless current_user.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end
