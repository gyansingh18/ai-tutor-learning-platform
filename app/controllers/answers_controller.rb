class AnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question

  def create
    @answer = @question.build_answer(answer_params)

    if @answer.save
      redirect_to @question, notice: 'Answer created successfully!'
    else
      redirect_to @question, alert: 'Failed to create answer.'
    end
  end

  private

  def set_question
    @question = Question.find(params[:question_id])
  end

  def answer_params
    params.require(:answer).permit(:content)
  end
end
