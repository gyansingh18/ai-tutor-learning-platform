class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  # before_action :authenticate_user!

  def index
    @learning_stats = get_learning_stats if user_signed_in?
    @resume_chapter = get_resume_chapter if user_signed_in?

    # Prepare REAL data from S3 for dependent selects (same as questions controller)
    @subjects_by_grade = {}
    @chapters_by_subject = {}
    
    # Get real grades from S3 bucket structure
    real_grades = get_real_grades_from_s3
    
    real_grades.each do |grade_number|
      grade = Grade.find_or_create_by(name: "Grade #{grade_number}") do |g|
        g.description = "Grade #{grade_number} content"
      end
      
      # Ensure the grade is saved and has an ID
      if grade.id.nil?
        grade.save!
      end
      
      # Get real subjects for this grade from S3
      real_subjects = get_real_subjects_from_s3(grade_number)
      
      @subjects_by_grade[grade.id] = real_subjects.map { |subject_name| 
        subject = Subject.find_or_create_by(name: subject_name, grade: grade) do |s|
          s.description = "#{subject_name} for #{grade.name}"
        end
        { id: subject.id, name: subject.name } 
      }
      
      # Get real chapters for each subject from S3
      real_subjects.each do |subject_name|
        subject = Subject.find_by(name: subject_name, grade: grade)
        next unless subject
        
        real_chapters = get_real_chapters_from_s3(grade_number, subject_name)
        @chapters_by_subject[subject.id] = real_chapters.map { |chapter_name|
          chapter = Chapter.find_or_create_by(name: chapter_name, subject: subject) do |c|
            c.description = "#{chapter_name} content"
          end
          { id: chapter.id, name: chapter.name }
        }
      end
    end
  end

  private

  # Get real grades from S3 bucket structure (same as questions controller)
  def get_real_grades_from_s3
    begin
      # List all objects in bucket to find class folders
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: 'pdfs/', delimiter: '/')
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

  # Get real subjects for a grade from S3 (same as questions controller)
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

  # Get real chapters for a subject from S3 (same as questions controller)
  def get_real_chapters_from_s3(grade_number, subject_name)
    begin
      prefix = "pdfs/class_#{grade_number}/#{subject_name.to_s.parameterize}/"
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: prefix)
      chapters = []
      
      resp.contents.each do |obj|
        if obj.key.end_with?('.pdf')
          # Extract chapter name from filename
          filename = File.basename(obj.key, '.pdf')
          
          # Handle different naming patterns
          if filename.match(/jeff(\d+)/)
            chapter_num = $1.to_i
            chapters << "Chapter #{chapter_num}"
          elsif filename.match(/chapter_(\d+)/)
            chapter_num = $1.to_i
            chapters << "Chapter #{chapter_num}"
          elsif filename.match(/^(\d+)$/)
            chapter_num = $1.to_i
            chapters << "Chapter #{chapter_num}"
          else
            # Use the actual filename as chapter name
            chapters << filename.humanize
          end
        end
      end
      
      # Sort chapters by number if possible
      chapters.sort_by { |ch| ch.match(/\d+/).to_s.to_i }
    rescue => e
      Rails.logger.error "Error getting chapters from S3: #{e.message}"
      []
    end
  end

  def get_learning_stats
    return nil unless user_signed_in?

    # Get user's learning progress
    chapters_with_progress = Chapter.joins(tasks: :student_answers)
                                   .where(student_answers: { user: current_user })
                                   .distinct

    total_chapters_started = chapters_with_progress.count
    completed_chapters = chapters_with_progress.select do |chapter|
      total_tasks = chapter.tasks.count
      completed_tasks = chapter.tasks.joins(:student_answers)
                               .where(student_answers: { user: current_user })
                               .distinct.count
      total_tasks > 0 && completed_tasks >= total_tasks
    end.count

    total_tasks_completed = StudentAnswer.where(user: current_user).count
    correct_answers = StudentAnswer.where(user: current_user, is_correct: true).count
    accuracy_rate = total_tasks_completed > 0 ? (correct_answers.to_f / total_tasks_completed * 100).round : 0

    {
      total_chapters_started: total_chapters_started,
      completed_chapters: completed_chapters,
      total_tasks_completed: total_tasks_completed,
      correct_answers: correct_answers,
      accuracy_rate: accuracy_rate
    }
  end

  def get_resume_chapter
    return nil unless user_signed_in?

    # Find the most recent chapter with incomplete progress
    incomplete_chapters = Chapter.joins(tasks: :student_answers)
                                .where(student_answers: { user: current_user })
                                .distinct
                                .select do |chapter|
      total_tasks = chapter.tasks.count
      completed_tasks = chapter.tasks.joins(:student_answers)
                               .where(student_answers: { user: current_user })
                               .distinct.count
      total_tasks > 0 && completed_tasks < total_tasks
    end

    # Return the most recent one (by latest student answer)
    if incomplete_chapters.any?
      latest_answer = StudentAnswer.where(user: current_user, task: incomplete_chapters.flat_map(&:tasks))
                                  .order(created_at: :desc)
                                  .first

      if latest_answer
        latest_answer.task.chapter
      else
        incomplete_chapters.first
      end
    else
      nil
    end
  end
end
