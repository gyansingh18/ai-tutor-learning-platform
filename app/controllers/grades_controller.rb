class GradesController < ApplicationController
  # before_action :authenticate_user!  # Now handled globally

  def index
    @grades = if current_user.admin?
                Grade.ordered
              elsif current_user.allowed_grade.present?
                # User can only access specific grade
                Grade.where(name: "Grade #{current_user.allowed_grade}").ordered
              else
                # User can access all grades
                Grade.ordered
              end
  end

  def show
    @grade = Grade.find(params[:id])
    
    # Check if user has access to this grade
    unless current_user.can_access_grade?(@grade.name.match(/Grade (\d+)/)[1])
      redirect_to grades_path, alert: "You don't have access to #{@grade.display_name}. #{current_user.grade_restriction_message}"
      return
    end

    @subjects = @grade.subjects.ordered
    @pdf_materials = @grade.pdf_materials.recent.limit(5)

    # Get S3 PDF files for this grade
    begin
      grade_number = @grade.name.match(/Grade (\d+)/)[1]
      prefix = "pdfs/class_#{grade_number}/"
      
      @s3_pdfs = S3ListService.new.list_pdfs(prefix: prefix)
    rescue => e
      Rails.logger.error "Error fetching S3 PDFs for grade #{@grade.name}: #{e.message}"
      @s3_pdfs = []
    end
  end

  private

  def set_grade
    @grade = Grade.find(params[:id])
  end
end
