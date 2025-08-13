class QuestionsController < ApplicationController
  # before_action :authenticate_user!  # Now handled globally
  skip_before_action :authenticate_user!, only: [:new]
  before_action :authenticate_user!, only: [:create, :index, :show]
  before_action :set_grade_and_subject_and_chapter, only: [:new, :create], if: -> { params[:grade_id].present? }

  def index
    @questions = current_user.questions.recent.includes(:chapter, :answer)
  end

  def show
    @question = Question.find(params[:id])
    @answer = @question.answer
  end

  def new
    @question = Question.new

    # Pre-select chapter if chapter_id is provided
    if params[:chapter_id].present?
      @question.chapter_id = params[:chapter_id]
      @selected_chapter = Chapter.find(params[:chapter_id])
    end

    # Only show user-specific data if authenticated
    if user_signed_in?
      @chapters = Chapter.ordered.includes(:subject => :grade) if params[:grade_id].blank?
    end

    # Use cached S3 data instead of scanning on every request
    @subjects_by_grade = get_cached_subjects_by_grade
    @chapters_by_subject = get_cached_chapters_by_subject
  end

  def create
    @question = current_user.questions.build(question_params)

    # Set chapter based on context
    if params[:grade_id].present?
      @question.chapter = @chapter
    else
      @question.chapter = Chapter.find(question_params[:chapter_id]) if question_params[:chapter_id].present?
    end

    if @question.save
      # Generate answer using RAG
      rag_service = RagService.new(@question.chapter)
      answer_content = rag_service.answer_question(@question.content)

      @question.create_answer(content: answer_content)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "question-form",
            partial: "questions/answer_result",
            locals: { question: @question }
          )
        end
        format.html { redirect_to @question, notice: 'Question asked successfully!' }
      end
    else
      @chapters = Chapter.ordered.includes(:subject => :grade) if params[:grade_id].blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "question-form",
            partial: "form",
            locals: { question: @question }
          ), status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_grade_and_subject_and_chapter
    @grade = Grade.find(params[:grade_id])
    @subject = @grade.subjects.find(params[:subject_id])
    @chapter = @subject.chapters.find(params[:chapter_id])
  end

  def question_params
    if params[:grade_id].present?
      params.require(:question).permit(:content)
    else
      params.require(:question).permit(:content, :chapter_id, :grade_id, :subject_id)
    end
  end

  # Get real grades from S3 bucket structure
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

  # Get real chapters for a subject from S3
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

  # Cached methods to prevent S3 scanning on every request
  def get_cached_subjects_by_grade
    Rails.cache.fetch("subjects_by_grade", expires_in: 30.minutes) do
      subjects_by_grade = {}
      
      # Get existing records from database instead of scanning S3
      Grade.includes(subjects: :chapters).each do |grade|
        subjects_by_grade[grade.id.to_s] = grade.subjects.map do |subject|
          { id: subject.id, name: subject.name }
        end
      end
      
      subjects_by_grade
    end
  end

  def get_cached_chapters_by_subject
    Rails.cache.fetch("chapters_by_subject", expires_in: 30.minutes) do
      chapters_by_subject = {}
      
      # Get existing records from database instead of scanning S3
      Subject.includes(:chapters).each do |subject|
        chapters_by_subject[subject.id.to_s] = subject.chapters.map do |chapter|
          { id: chapter.id, name: chapter.name }
        end
      end
      
      chapters_by_subject
    end
  end
end
