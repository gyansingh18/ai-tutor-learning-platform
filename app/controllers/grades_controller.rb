class GradesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    # Get real grades from S3 bucket structure
    @grades = get_real_grades_from_s3.map do |grade_number|
      Grade.find_or_create_by(name: "Grade #{grade_number}")
    end
  end

  def show
    @grade = Grade.find(params[:id])
    
    # Get real subjects for this grade from S3
    grade_number = @grade.name.match(/Grade (\d+)/)[1].to_i
    @subjects = get_real_subjects_from_s3(grade_number).map do |subject_name|
      Subject.find_or_create_by(name: subject_name, grade: @grade)
    end
  end

  private

  # Get real grades from S3 bucket structure
  def get_real_grades_from_s3
    begin
      # List all objects in bucket to find class folders
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, delimiter: '/')
      grades = []
      
      resp.common_prefixes.each do |prefix|
        if prefix.prefix.match(/pdfs\/class_(\d+)\//)
          grades << $1.to_i
        end
      end
      
      grades.sort
    rescue => e
      Rails.logger.error "Error getting grades from S3: #{e.message}"
      []
    end
  end

  # Get real subjects for a grade from S3
  def get_real_subjects_from_s3(grade_number)
    begin
      prefix = "pdfs/class_#{grade_number}/"
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: prefix, delimiter: '/')
      subjects = []
      
      resp.common_prefixes.each do |prefix_obj|
        if prefix_obj.prefix.match(/pdfs\/class_\d+\/([^\/]+)\//)
          subjects << $1.humanize
        end
      end
      
      subjects.sort
    rescue => e
      Rails.logger.error "Error getting subjects from S3: #{e.message}"
      []
    end
  end
end
