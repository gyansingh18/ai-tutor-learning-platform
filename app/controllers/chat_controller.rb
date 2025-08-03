class ChatController < ApplicationController
  before_action :authenticate_user!

  def index
    @chapter = Chapter.find(params[:chapter_id]) if params[:chapter_id].present?
    @conversations = current_user.questions.includes(:answer, :chapter).recent.limit(10)
  end

  def show
    @chapter = Chapter.find(params[:chapter_id])
    @questions = current_user.questions.where(chapter: @chapter).includes(:answer).order(:created_at)
    @question = Question.new
  end

  def create
    @chapter = Chapter.find(params[:chapter_id])
    @question = current_user.questions.build(question_params)
    @question.chapter = @chapter

    Rails.logger.info "Chat create action - Format: #{request.format}"
    Rails.logger.info "Chat create action - Parameters: #{params}"

    if @question.save
      # Generate answer using RAG with conversation history
      begin
        rag_service = RagService.new(@chapter)

        # Get conversation history for this chapter (last 5 Q&A pairs)
        conversation_history = get_conversation_history(@chapter)

        Rails.logger.info "Conversation history count: #{conversation_history.length}"
        Rails.logger.info "Conversation history: #{conversation_history.inspect}"

        answer_content = rag_service.answer_question(@question.content, conversation_history)

        if answer_content.present?
          @question.create_answer(content: answer_content)
        else
          @question.create_answer(content: "I'm sorry, I'm having trouble processing your question right now. Please try again in a moment.")
        end
      rescue => e
        Rails.logger.error "AI Response Error: #{e.message}"
        @question.create_answer(content: "I'm sorry, I'm having trouble processing your question right now. Please try again in a moment.")
      end

      respond_to do |format|
        format.turbo_stream {
          Rails.logger.info "Rendering Turbo Stream response"
          render turbo_stream: [
            # Append the new question and answer to chat messages
            turbo_stream.append(
              "chat_messages",
              partial: "chat/message_pair",
              locals: { question: @question }
            ),
            # Replace the form with a fresh one
            turbo_stream.replace(
              "chat_form",
              partial: "chat/form",
              locals: { question: Question.new, chapter: @chapter }
            )
          ]
        }
        format.html {
          Rails.logger.info "Rendering HTML redirect"
          redirect_to chat_path(@chapter)
        }
      end
    else
      # Set @questions for error case
      @questions = current_user.questions.where(chapter: @chapter).includes(:answer).order(:created_at)

      respond_to do |format|
        format.turbo_stream {
          Rails.logger.info "Rendering Turbo Stream error response"
          render turbo_stream: [
            turbo_stream.replace(
              "chat_form",
              partial: "chat/form",
              locals: { question: @question, chapter: @chapter }
            ),
            turbo_stream.update("flash_messages", partial: "shared/flash", locals: {
              flash: { error: @question.errors.full_messages.join(", ") }
            })
          ]
        }
        format.html {
          Rails.logger.info "Rendering HTML error response"
          flash.now[:error] = @question.errors.full_messages.join(", ")
          render :show
        }
      end
    end
  end

  private

  def question_params
    params.require(:question).permit(:content)
  end

  def get_conversation_history(chapter)
    # Get the last 5 answered questions for this chapter (excluding the current one)
    previous_questions = current_user.questions
                                   .where(chapter: chapter)
                                   .where.not(id: @question&.id)
                                   .includes(:answer)
                                   .where.not(answers: { id: nil })
                                   .order(:created_at)
                                   .last(5)

    Rails.logger.info "Previous questions count: #{previous_questions.length}"
    Rails.logger.info "Previous questions IDs: #{previous_questions.map(&:id)}"

    # Convert to conversation history format
    previous_questions.map do |question|
      {
        question: question.content,
        answer: question.answer.content
      }
    end
  end
end
