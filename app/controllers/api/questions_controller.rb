class Api::QuestionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @question = current_user.questions.build(question_params)

    if @question.save
      # Generate answer using RAG
      rag_service = RagService.new(@question.chapter)
      answer_content = rag_service.answer_question(@question.content)

      @answer = @question.create_answer(content: answer_content)

      render json: {
        success: true,
        question: {
          id: @question.id,
          content: @question.content,
          created_at: @question.created_at
        },
        answer: {
          id: @answer.id,
          content: @answer.content,
          created_at: @answer.created_at
        }
      }
    else
      render json: { success: false, errors: @question.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def question_params
    params.require(:question).permit(:content, :chapter_id)
  end
end
