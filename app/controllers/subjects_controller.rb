class SubjectsController < ApplicationController
  def index
    @subjects = Subject.includes(:grade).ordered
  end

  def show
    @subject = Subject.find(params[:id])
    
    # Get real chapters for this subject from S3
    grade_number = @subject.grade.name.match(/Grade (\d+)/)[1].to_i
    @chapters = get_real_chapters_from_s3(grade_number, @subject.name).map do |chapter_name|
      Chapter.find_or_create_by(name: chapter_name, subject: @subject)
    end
  end

  private

  # Get real chapters for a subject from S3
  def get_real_chapters_from_s3(grade_number, subject_name)
    begin
      prefix = "grade_#{grade_number}/#{subject_name.to_s.parameterize}/"
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: prefix)
      chapters = []
      
      resp.contents.each do |obj|
        if obj.key.end_with?('.pdf')
          # Extract chapter name from filename (e.g., "ch1.pdf" -> "Chapter 1")
          filename = File.basename(obj.key, '.pdf')
          if filename.match(/ch(\d+)/)
            chapter_num = $1.to_i
            chapters << "Chapter #{chapter_num}"
          elsif filename.match(/chapter_(\d+)/)
            chapter_num = $1.to_i
            chapters << "Chapter #{chapter_num}"
          else
            # Use filename as chapter name
            chapters << filename.humanize
          end
        end
      end
      
      chapters.sort_by { |ch| ch.match(/\d+/).to_s.to_i }
    rescue => e
      Rails.logger.error "Error getting chapters from S3: #{e.message}"
      []
    end
  end
end
