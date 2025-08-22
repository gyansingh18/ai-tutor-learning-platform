class ChaptersController < ApplicationController
  # before_action :authenticate_user!  # Now handled globally
  before_action :set_grade_and_subject_and_chapter
  before_action :check_grade_access

  def index
    @chapters = @subject.chapters.ordered
  end

  def show
    @chapter = @subject.chapters.find(params[:id])
    @tasks = @chapter.tasks.ordered
    @pdf_materials = @chapter.pdf_materials.recent.limit(5)

    # Get S3 PDF files for this chapter
    begin
      grade_number = @grade.name.match(/Grade (\d+)/)[1]
      subject_name = @subject.name
      chapter_num = @chapter.name.match(/Chapter (\d+)/)[1]
      
      # Try different possible PDF filename patterns
      possible_paths = [
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/jeff#{chapter_num}.pdf",
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/chapter_#{chapter_num}.pdf",
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/#{chapter_num}.pdf",
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/#{@chapter.name.to_s.parameterize}.pdf"
      ]
      
      @s3_pdfs = S3ListService.new.list_pdfs(prefix: "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/")
    rescue => e
      Rails.logger.error "Error fetching S3 PDFs for chapter #{@chapter.name}: #{e.message}"
      @s3_pdfs = []
    end
  end

  private

  def set_grade_and_subject_and_chapter
    @grade = Grade.find(params[:grade_id])
    @subject = @grade.subjects.find(params[:subject_id])
    @chapter = @subject.chapters.find(params[:id]) if params[:id].present?
  end

  def check_grade_access
    unless current_user.can_access_grade?(@grade.name.match(/Grade (\d+)/)[1])
      redirect_to grades_path, alert: "You don't have access to #{@grade.display_name}. #{current_user.grade_restriction_message}"
    end
  end
end
