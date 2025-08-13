class ChaptersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @chapters = Chapter.includes(:subject => :grade).ordered
  end

  def show
    @chapter = Chapter.find(params[:id])

    # Get real PDF files for this chapter from S3
    grade_number = @chapter.subject.grade.name.match(/Grade (\d+)/)[1].to_i
    @pdf_files = get_real_pdf_files_from_s3(grade_number, @chapter.subject.name, @chapter.name)
  end

  private

  # Get real PDF files for a chapter from S3
  def get_real_pdf_files_from_s3(grade_number, subject_name, chapter_name)
    begin
      # Extract chapter number from chapter name
      chapter_num = chapter_name.match(/\d+/).to_s.to_i

      # Try different possible filename patterns based on actual S3 structure
      possible_keys = [
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/jeff#{chapter_num}.pdf",
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/chapter_#{chapter_num}.pdf",
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/#{chapter_num}.pdf",
        "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/#{chapter_name.to_s.parameterize}.pdf"
      ]

      pdf_files = []
      possible_keys.each do |key|
        if S3_CLIENT.head_object(bucket: S3_BUCKET, key: key)
          pdf_files << {
            key: key,
            url: s3_signed_url(key),
            filename: File.basename(key)
          }
        end
      end

      pdf_files
    rescue => e
      Rails.logger.error "Error getting PDF files from S3: #{e.message}"
      []
    end
  end
end
