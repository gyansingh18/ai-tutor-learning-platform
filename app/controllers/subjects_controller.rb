class SubjectsController < ApplicationController
  before_action :authenticate_user!, except: [:chapters]
  before_action :set_grade

  def index
    @subjects = @grade.subjects.ordered

    respond_to do |format|
      format.html
      format.json { render json: @subjects.map { |subject| { id: subject.id, name: subject.display_name } } }
    end
  end

  def show
    @subject = @grade.subjects.find(params[:id])
    @chapters = @subject.chapters.ordered
  end

  def chapters
    @subject = @grade.subjects.find(params[:subject_id])
    @chapters = @subject.chapters.ordered
    render json: @chapters.map { |chapter| { id: chapter.id, name: chapter.name } }
  end

  private

  def set_grade
    @grade = Grade.find(params[:grade_id])
  end
end
