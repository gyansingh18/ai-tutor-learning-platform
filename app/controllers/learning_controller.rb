class LearningController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chapter
  before_action :set_task, only: [:show_task, :submit_answer, :next_task, :previous_task]

  def index
    @chapter = Chapter.find(params[:chapter_id])

    # Generate tasks automatically if they don't exist
    if @chapter.tasks.empty?
      TaskGeneratorService.new(@chapter).generate_tasks
    end

    @first_task = @chapter.first_task

    if @first_task
      redirect_to learning_task_path(@chapter, @first_task)
    else
      flash[:alert] = "No tasks available for this chapter."
      redirect_to chat_path(@chapter)
    end
  end

  def show_task
    @current_task = @task
    @student_answer = @task.student_answers.find_by(user: current_user)
    @progress = calculate_progress

    # For both HTML and Turbo Stream, render the same view
    # Rails will automatically handle the Turbo Frame replacement
  end

  def submit_answer
    answer = params[:answer]

    # Use AI to evaluate the answer
    is_correct = evaluate_answer(@task, answer)

    @student_answer = @task.student_answers.find_or_initialize_by(user: current_user)
    @student_answer.answer = answer
    @student_answer.is_correct = is_correct
    @student_answer.save!

    # Redirect back to the same page to show the result
    redirect_to learning_task_path(@chapter, @task)
  end

  def next_task
    next_task_obj = @task.next_task

    if next_task_obj
      @task = next_task_obj
      @current_task = @task
      @student_answer = @task.student_answers.find_by(user: current_user)
      @progress = calculate_progress
      # Ensure @chapter is set correctly
      @chapter = @task.chapter
      render :show_task
    else
      flash[:notice] = "Congratulations! You've completed all tasks in this chapter."
      redirect_to chat_path(@chapter)
    end
  end

  def previous_task
    previous_task_obj = @task.previous_task

    if previous_task_obj
      @task = previous_task_obj
      @current_task = @task
      @student_answer = @task.student_answers.find_by(user: current_user)
      @progress = calculate_progress
      # Ensure @chapter is set correctly
      @chapter = @task.chapter
      render :show_task
    else
      redirect_to learning_task_path(@chapter, @task)
    end
  end

  private

  def set_chapter
    @chapter = Chapter.find(params[:chapter_id])
  end

  def set_task
    @task = @chapter.tasks.find(params[:task_id])
  end

  def calculate_progress
    total_tasks = @chapter.total_tasks
    completed_tasks = @chapter.tasks.joins(:student_answers)
                              .where(student_answers: { user: current_user, is_correct: true })
                              .distinct.count

    return 0 if total_tasks == 0
    (completed_tasks.to_f / total_tasks * 100).round
  end

  def evaluate_answer(task, answer)
    # Use AI to evaluate the answer based on task type
    case task.task_type
    when 'multiple_choice'
      # For multiple choice, we can store correct answer in task content
      correct_answer = task.content.match(/Correct Answer: (.+)/)&.[](1)&.strip
      answer.strip.downcase == correct_answer&.downcase
    when 'true_false'
      correct_answer = task.content.match(/Correct Answer: (.+)/)&.[](1)&.strip
      answer.strip.downcase == correct_answer&.downcase
    when 'fill_in_blank'
      # Use AI to evaluate fill-in-the-blank
      evaluate_with_ai(task, answer)
    when 'coding'
      # Use AI to evaluate coding tasks
      evaluate_with_ai(task, answer)
    when 'short_answer'
      # Use AI to evaluate short answers
      evaluate_with_ai(task, answer)
    else
      false
    end
  end

  def evaluate_with_ai(task, answer)
    # Use OpenAI to evaluate the answer
    prompt = "Task: #{task.title}\n\nContent: #{task.content}\n\nStudent Answer: #{answer}\n\nEvaluate if the student's answer is correct. Respond with only 'YES' or 'NO'."

    begin
      response = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY']).chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 10,
          temperature: 0
        }
      )

      result = response.dig("choices", 0, "message", "content")&.strip&.upcase
      result == "YES"
    rescue => e
      Rails.logger.error "AI evaluation failed: #{e.message}"
      false
    end
  end
end
