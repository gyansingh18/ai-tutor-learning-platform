class GradesController < ApplicationController
  before_action :authenticate_user!, except: [:subjects]

  def index
    @grades = Grade.ordered
  end

  def show
    @grade = Grade.find(params[:id])
    @subjects = @grade.subjects.ordered
  end

  def subjects
    @grade = Grade.find(params[:grade_id])
    @subjects = @grade.subjects.ordered
    render json: @subjects.map { |subject| { id: subject.id, name: subject.name } }
  end
end
