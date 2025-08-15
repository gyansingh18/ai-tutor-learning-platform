class Api::SubjectsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def chapters
    @subject = Subject.find(params[:id])
    # Only return chapters that have vector chunks available
    @chapters = @subject.chapters.with_vector_chunks.ordered
    render json: @chapters.map { |chapter| { id: chapter.id, name: chapter.name } }
  end
end
