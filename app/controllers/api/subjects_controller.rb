class Api::SubjectsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def chapters
    @subject = Subject.find(params[:id])
    @chapters = @subject.chapters.ordered
    render json: @chapters.map { |chapter| { id: chapter.id, name: chapter.name } }
  end
end
