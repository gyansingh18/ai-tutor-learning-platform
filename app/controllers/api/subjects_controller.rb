class Api::SubjectsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def chapters
    @grade = Grade.find(params[:grade_id])
    @subject = @grade.subjects.find(params[:subject_id])
    @chapters = @subject.chapters.ordered
    render json: @chapters.map { |chapter| { id: chapter.id, name: chapter.name } }
  end
end
