class SubjectsController < ApplicationController
  # before_action :authenticate_user!  # Now handled globally
  before_action :set_grade
  before_action :check_grade_access

  def index
    @subjects = @grade.subjects.ordered
  end

  def show
    @subject = @grade.subjects.find(params[:id])
    @chapters = @subject.chapters.ordered
    @pdf_materials = @subject.pdf_materials.recent.limit(5)

    # Get S3 PDF files for this subject
    begin
      grade_number = @grade.name.match(/Grade (\d+)/)[1]
      subject_name = @subject.name
      prefix = "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/"
      
      @s3_pdfs = S3ListService.new.list_pdfs(prefix: prefix)
    rescue => e
      Rails.logger.error "Error fetching S3 PDFs for subject #{@subject.name}: #{e.message}"
      @s3_pdfs = []
    end
  end

  private

  def set_grade
    @grade = Grade.find(params[:grade_id])
  end

  def check_grade_access
    unless current_user.can_access_grade?(@grade.name.match(/Grade (\d+)/)[1])
      redirect_to grades_path, alert: "You don't have access to #{@grade.display_name}. #{current_user.grade_restriction_message}"
    end
  end
end
