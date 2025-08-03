class TaskGeneratorService
  def initialize(chapter)
    @chapter = chapter
  end

  def generate_tasks
    Rails.logger.info "Starting task generation for chapter: #{@chapter.name}"

    # Get chapter content from PDF materials or existing content
    chapter_content = get_chapter_content
    Rails.logger.info "Chapter content: #{chapter_content}"

    # Use AI to break down the content into learning tasks
    tasks_data = generate_tasks_with_ai(chapter_content)
    Rails.logger.info "AI generated #{tasks_data['tasks'].count} tasks"

    # Create tasks in the database
    create_tasks_from_ai_response(tasks_data)
    Rails.logger.info "Successfully created #{@chapter.tasks.count} tasks"
  end

  private

  def get_chapter_content
    # Try to get content from PDF materials first
    pdf_material = @chapter.pdf_materials.first
    if pdf_material&.title.present?
      # Use the PDF material title and chapter information
      content = "Chapter: #{@chapter.name}\n"
      content += "Subject: #{@chapter.subject.name}\n"
      content += "Grade: #{@chapter.subject.grade.name}\n"
      content += "PDF Material: #{pdf_material.title}\n"
      return content
    end

    # Fallback to chapter and subject information
    content = "Chapter: #{@chapter.name}\n"
    content += "Subject: #{@chapter.subject.name}\n"
    content += "Grade: #{@chapter.subject.grade.name}\n"
    content += "Description: #{@chapter.description}" if @chapter.description.present?
    return content
  end

  def generate_tasks_with_ai(content)
    prompt = <<~PROMPT
      You are an expert educational content creator. Create 6-10 comprehensive learning tasks for the following educational content.

      Content Information:
      #{content}

      Create engaging, progressive learning tasks that follow this structure:

      **For each task, provide:**
      1. **Concept Explanation**: A detailed, clear explanation of the concept being taught (2-3 paragraphs)
      2. **Question**: A specific question that tests understanding of the explained concept
      3. **Options/Hint**: Appropriate options for multiple choice or helpful hints
      4. **Correct Answer**: The accurate answer with brief explanation

      **Task Progression:**
      - Start with foundational concepts
      - Progress to application and analysis
      - Include different question types for variety
      - Make each task build upon previous knowledge

      **Question Types to Include:**
      - Multiple choice (40% of tasks)
      - Fill in the blank (20% of tasks)
      - True/False (20% of tasks)
      - Short answer (15% of tasks)
      - Coding/Problem solving (5% of tasks)

      Create tasks in this JSON format:
      {
        "tasks": [
          {
            "title": "Task Title (e.g., 'Understanding Basic Concepts')",
            "explanation": "Detailed explanation of the concept (2-3 paragraphs explaining the topic clearly)",
            "task_type": "multiple_choice|fill_in_blank|true_false|short_answer|coding",
            "question": "Specific question that tests the explained concept",
            "options": ["A", "B", "C", "D"] (only for multiple_choice),
            "correct_answer": "The correct answer with brief explanation",
            "hint": "A helpful hint that guides students without giving away the answer"
          }
        ]
      }

      **Requirements:**
      - Make explanations educational and informative, not just question context
      - Ensure questions directly relate to the explanation provided
      - Create progressive difficulty (easier to harder)
      - Include real-world examples in explanations when relevant
      - Make content age-appropriate for the grade level
      - Ensure explanations are comprehensive enough to answer the question
      - Vary question types to maintain engagement
    PROMPT

    begin
      response = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY']).chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 3000,
          temperature: 0.7
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_ai_response(content)
    rescue => e
      Rails.logger.error "AI task generation failed: #{e.message}"
      generate_fallback_tasks
    end
  end

  def parse_ai_response(content)
    # Try to extract JSON from the response
    json_match = content.match(/\{.*\}/m)
    if json_match
      JSON.parse(json_match[0])
    else
      generate_fallback_tasks
    end
  rescue JSON::ParserError
    generate_fallback_tasks
  end

  def generate_fallback_tasks
    {
      "tasks" => [
        {
          "title" => "Understanding #{@chapter.name} - Basic Concepts",
          "explanation" => "#{@chapter.name} is a fundamental topic in #{@chapter.subject.name}. This chapter introduces the core concepts that students need to understand. The basic principles covered here will serve as the foundation for more advanced topics later in the course. Understanding these concepts thoroughly will help students build a strong knowledge base for future learning.",
          "task_type" => "multiple_choice",
          "question" => "What is the primary purpose of studying #{@chapter.name}?",
          "options" => ["To memorize facts", "To build foundational knowledge", "To complete assignments", "To pass exams"],
          "correct_answer" => "To build foundational knowledge",
          "hint" => "Think about how this chapter relates to the overall subject and future learning."
        },
        {
          "title" => "Key Principles in #{@chapter.name}",
          "explanation" => "In this section, we explore the key principles that make #{@chapter.name} important. These principles help us understand how different elements work together and why certain approaches are more effective than others. By understanding these principles, students can apply their knowledge to various situations and problems they might encounter.",
          "task_type" => "fill_in_blank",
          "question" => "The most important principle in #{@chapter.name} is ___.",
          "correct_answer" => "understanding",
          "hint" => "What is the main goal when learning any new concept?"
        },
        {
          "title" => "Application of Concepts",
          "explanation" => "Now that we understand the basic concepts and principles, it's time to see how they apply in real-world situations. This application helps students connect theoretical knowledge with practical use. Understanding how to apply these concepts is crucial for developing problem-solving skills and critical thinking abilities.",
          "task_type" => "true_false",
          "question" => "The concepts learned in #{@chapter.name} can be applied to solve real-world problems.",
          "correct_answer" => "True",
          "hint" => "Consider whether the knowledge from this chapter has practical value."
        },
        {
          "title" => "Advanced Understanding",
          "explanation" => "Building on the foundational concepts, we now explore more advanced aspects of #{@chapter.name}. This deeper understanding allows students to analyze complex situations and make informed decisions. Advanced understanding involves not just knowing the facts, but being able to explain why things work the way they do and how different factors interact.",
          "task_type" => "short_answer",
          "question" => "Explain how the concepts in #{@chapter.name} relate to the broader subject of #{@chapter.subject.name}.",
          "correct_answer" => "The concepts in #{@chapter.name} provide the foundation for understanding more complex topics in #{@chapter.subject.name}.",
          "hint" => "Think about how basic concepts support advanced learning."
        },
        {
          "title" => "Critical Analysis",
          "explanation" => "Critical analysis involves examining information carefully and making reasoned judgments. In #{@chapter.name}, this means being able to evaluate different approaches, identify strengths and weaknesses, and understand the implications of various choices. This skill is essential for academic success and real-world problem solving.",
          "task_type" => "multiple_choice",
          "question" => "Which skill is most important for analyzing #{@chapter.name} concepts?",
          "options" => ["Memorization", "Critical thinking", "Speed reading", "Note-taking"],
          "correct_answer" => "Critical thinking",
          "hint" => "Consider what skill helps you understand and evaluate information effectively."
        },
        {
          "title" => "Synthesis and Integration",
          "explanation" => "The final step in mastering #{@chapter.name} is the ability to synthesize and integrate different concepts. This means combining various pieces of knowledge to form a comprehensive understanding. Students who can synthesize information are better equipped to tackle complex problems and adapt to new situations.",
          "task_type" => "true_false",
          "question" => "Synthesizing information from #{@chapter.name} helps students solve complex problems.",
          "correct_answer" => "True",
          "hint" => "Think about how combining different concepts leads to better problem-solving abilities."
        }
      ]
    }
  end

  def create_tasks_from_ai_response(tasks_data)
    tasks_data["tasks"].each_with_index do |task_data, index|
      content = build_task_content(task_data)

      @chapter.tasks.create!(
        title: task_data["title"],
        content: content,
        task_type: task_data["task_type"],
        order: index + 1
      )
    end
  end

  def build_task_content(task_data)
    content = "#{task_data['explanation']}\n\n"
    content += "Question: #{task_data['question']}\n\n"

    if task_data["options"]
      task_data["options"].each_with_index do |option, index|
        content += "Option #{('A'.ord + index).chr}: #{option}\n"
      end
      content += "\n"
    end

    content += "Hint: #{task_data['hint']}\n\n"
    content += "Correct Answer: #{task_data['correct_answer']}"

    content
  end
end
