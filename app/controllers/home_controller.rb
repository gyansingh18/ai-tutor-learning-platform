class HomeController < ApplicationController
  # before_action :authenticate_user!  # Now handled globally

  def index
    if user_signed_in?
      @user = current_user
      
      # Get grades based on user permissions
      @grades = if current_user.admin?
                  Grade.ordered
                elsif current_user.allowed_grade.present?
                  # User can only access specific grade
                  Grade.where(name: "Grade #{current_user.allowed_grade}").ordered
                else
                  # User can access all grades
                  Grade.ordered
                end

      # Get recent questions for the user
      @recent_questions = current_user.questions.recent.limit(5).includes(:chapter, :answer)

      # Get S3 PDF files for accessible grades
      @s3_pdfs = []
      @grades.each do |grade|
        begin
          grade_number = grade.name.match(/Grade (\d+)/)[1]
          prefix = "pdfs/class_#{grade_number}/"
          
          grade_pdfs = S3ListService.new.list_pdfs(prefix: prefix)
          @s3_pdfs.concat(grade_pdfs)
        rescue => e
          Rails.logger.error "Error fetching S3 PDFs for grade #{grade.name}: #{e.message}"
        end
      end

      # Limit to recent PDFs
      @s3_pdfs = @s3_pdfs.sort_by { |pdf| pdf[:last_modified] }.reverse.first(10)
    else
      # For non-authenticated users, show all grades
      @grades = Grade.ordered
      
      # Get S3 PDF files for all grades
      @s3_pdfs = []
      @grades.each do |grade|
        begin
          grade_number = grade.name.match(/Grade (\d+)/)[1]
          prefix = "pdfs/class_#{grade_number}/"
          
          grade_pdfs = S3ListService.new.list_pdfs(prefix: prefix)
          @s3_pdfs.concat(grade_pdfs)
        rescue => e
          Rails.logger.error "Error fetching S3 PDFs for grade #{grade.name}: #{e.message}"
        end
      end

      # Limit to recent PDFs
      @s3_pdfs = @s3_pdfs.sort_by { |pdf| pdf[:last_modified] }.reverse.first(10)
    end
  end

  private

  def get_cached_subjects_by_grade
    Rails.cache.fetch("subjects_by_grade", expires_in: 1.hour) do
      subjects_by_grade = {}
      
      Grade.ordered.each do |grade|
        grade_number = grade.name.match(/Grade (\d+)/)[1]
        prefix = "pdfs/class_#{grade_number}/"
        
        begin
          subjects = S3ListService.new.list_subjects(prefix: prefix)
          subjects_by_grade[grade.id] = subjects
        rescue => e
          Rails.logger.error "Error fetching subjects for grade #{grade.name}: #{e.message}"
          subjects_by_grade[grade.id] = []
        end
      end
      
      subjects_by_grade
    end
  end

  def get_cached_chapters_by_subject
    Rails.cache.fetch("chapters_by_subject", expires_in: 1.hour) do
      chapters_by_subject = {}
      
      Grade.ordered.each do |grade|
        grade_number = grade.name.match(/Grade (\d+)/)[1]
        
        grade.subjects.each do |subject|
          subject_name = subject.name
          prefix = "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/"
          
          begin
            chapters = S3ListService.new.list_chapters(prefix: prefix)
            chapters_by_subject[subject.id] = chapters
          rescue => e
            Rails.logger.error "Error fetching chapters for subject #{subject.name}: #{e.message}"
            chapters_by_subject[subject.id] = []
          end
        end
      end
      
      chapters_by_subject
    end
  end
end
