class Api::GradesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def subjects
    @grade = Grade.find(params[:grade_id])
    @subjects = @grade.subjects.ordered
    render json: @subjects.map { |subject| { id: subject.id, name: subject.name } }
  end
end
