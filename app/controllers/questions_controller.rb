class QuestionsController < ApplicationController
  before_action :authenticate_user!
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

    @chapters = Chapter.ordered.includes(:subject, :grade) if params[:grade_id].blank?
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

      redirect_to @question, notice: 'Question asked successfully!'
    else
      @chapters = Chapter.ordered.includes(:subject, :grade) if params[:grade_id].blank?
      render :new, status: :unprocessable_entity
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
      params.require(:question).permit(:content, :chapter_id)
    end
  end
end
