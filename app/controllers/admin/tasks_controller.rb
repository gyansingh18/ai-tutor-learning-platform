class Admin::TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_chapter
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def index
    @tasks = @chapter.tasks.ordered
  end

  def show
  end

  def new
    @task = @chapter.tasks.build
  end

  def create
    @task = @chapter.tasks.build(task_params)

    if @task.save
      redirect_to admin_chapter_tasks_path(@chapter), notice: 'Task was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to admin_chapter_tasks_path(@chapter), notice: 'Task was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    redirect_to admin_chapter_tasks_path(@chapter), notice: 'Task was successfully deleted.'
  end

  private

  def set_chapter
    @chapter = Chapter.find(params[:chapter_id])
  end

  def set_task
    @task = @chapter.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :content, :task_type, :order)
  end

  def ensure_admin
    unless current_user.admin?
      redirect_to root_path, alert: 'Access denied.'
    end
  end
end
