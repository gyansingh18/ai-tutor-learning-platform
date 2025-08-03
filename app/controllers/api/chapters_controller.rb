class Api::ChaptersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chapter

  def show
    render json: {
      id: @chapter.id,
      name: @chapter.name,
      description: @chapter.description,
      subject: @chapter.subject.name,
      grade: @chapter.grade.name
    }
  end

  def explanation
    openai_service = OpenaiService.new
    explanation = openai_service.generate_chapter_explanation(@chapter)

    render json: { explanation: explanation }
  end

  private

  def set_chapter
    @chapter = Chapter.find(params[:id])
  end
end
