class Admin::ChaptersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_chapter, only: [:edit, :update, :destroy]

  def index
    @chapters = Chapter.includes(subject: :grade).ordered
  end

  def new
    @chapter = Chapter.new
    @subjects = Subject.includes(:grade).ordered
  end

  def create
    @chapter = Chapter.new(chapter_params)

    if @chapter.save
      redirect_to admin_chapters_path, notice: 'Chapter created successfully!'
    else
      @subjects = Subject.includes(:grade).ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @subjects = Subject.includes(:grade).ordered
  end

  def update
    if @chapter.update(chapter_params)
      redirect_to admin_chapters_path, notice: 'Chapter updated successfully!'
    else
      @subjects = Subject.includes(:grade).ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chapter.destroy
    redirect_to admin_chapters_path, notice: 'Chapter deleted successfully!'
  end

  def generate_tasks
    @chapter = Chapter.find(params[:id])

    begin
      TaskGeneratorService.new(@chapter).generate_tasks
      flash[:notice] = "AI has successfully generated #{@chapter.tasks.count} tasks for this chapter!"
    rescue => e
      flash[:alert] = "Failed to generate tasks: #{e.message}"
    end

    redirect_to admin_chapter_tasks_path(@chapter)
  end

  private

  def set_chapter
    @chapter = Chapter.find(params[:id])
  end

  def chapter_params
    params.require(:chapter).permit(:name, :description, :subject_id)
  end

  def ensure_admin!
    unless current_user.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end
