class ChaptersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_grade_and_subject

  def index
    @chapters = @subject.chapters.ordered

    respond_to do |format|
      format.html
      format.json { render json: @chapters.map { |chapter| { id: chapter.id, name: chapter.display_name } } }
    end
  end

  def show
    @chapter = @subject.chapters.find(params[:id])
    @questions = @chapter.questions.recent.limit(10)
    @pdf_materials = @chapter.pdf_materials.recent
  end

  private

  def set_grade_and_subject
    @grade = Grade.find(params[:grade_id])
    @subject = @grade.subjects.find(params[:subject_id])
  end
end
