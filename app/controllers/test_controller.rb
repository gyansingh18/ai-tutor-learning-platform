class TestController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chapters, only: [:index, :explain]

  def index
    @chapters = Chapter.includes(:subject => :grade).all
    @learning_styles = ['Visual', 'Kinesthetic', 'Auditory', 'Reading/Writing']
    @difficulty_levels = ['Beginner', 'Intermediate', 'Advanced']
    @interaction_types = ['Exploration', 'Practice', 'Assessment', 'Review']
  end

  def explain
    @chapter = Chapter.find(params[:chapter_id])
    @topic = params[:topic]
    @learning_style = params[:learning_style] || 'Visual'
    @difficulty = params[:difficulty] || 'Beginner'
    @interaction_type = params[:interaction_type] || 'Exploration'

    # Generate AI explanation with image
    @explanation = generate_visual_explanation(@chapter, @topic, @learning_style, @difficulty, @interaction_type)

    respond_to do |format|
      format.turbo_stream
      format.html { render :explain }
    end
  end

  def continue_explanation
    @chapter = Chapter.find(params[:chapter_id])
    @conversation_history = params[:conversation_history] || []
    @current_topic = params[:current_topic]
    @user_message = params[:user_message]
    @learning_style = params[:learning_style] || 'Visual'
    @difficulty = params[:difficulty] || 'Beginner'

    # Continue conversation with conditional image generation
    @response = continue_visual_conversation(@chapter, @conversation_history, @current_topic, @user_message, @learning_style, @difficulty)

    respond_to do |format|
      format.turbo_stream
      format.json { render json: @response }
    end
  end

  def batch_test
    # Test multiple topics at once
    @test_scenarios = generate_test_scenarios
  end

  def performance_test
    # Test system performance and reliability
    @performance_metrics = run_performance_tests
  end

  private

  def set_chapters
    @chapters = Chapter.includes(:subject => :grade).all
  end

  def generate_visual_explanation(chapter, topic, learning_style, difficulty, interaction_type)
    openai_service = OpenaiService.new

    # Generate DALL-E image prompt with learning style and difficulty
    image_prompt = generate_image_prompt(chapter, topic, learning_style, difficulty, interaction_type)

    # Generate text explanation with learning style adaptation
    text_prompt = generate_text_prompt(chapter, topic, learning_style, difficulty, interaction_type)

    begin
      # Generate image using DALL-E
      image_url = openai_service.generate_image(image_prompt)

      # Generate text explanation
      text_explanation = openai_service.generate_simple_text(text_prompt)

      {
        success: true,
        image_url: image_url,
        explanation: text_explanation,
        topic: topic,
        chapter: chapter,
        learning_style: learning_style,
        difficulty: difficulty,
        interaction_type: interaction_type,
        conversation_id: SecureRandom.uuid
      }
    rescue => e
      {
        success: false,
        error: e.message,
        explanation: "Sorry, I encountered an error while generating the explanation. Please try again.",
        topic: topic,
        chapter: chapter
      }
    end
  end

  def continue_visual_conversation(chapter, history, topic, user_message, learning_style, difficulty)
    openai_service = OpenaiService.new

    # Determine if we should generate a new image (not every time)
    should_generate_image = should_generate_new_image?(history, user_message)

    # Build conversation context
    conversation_context = build_conversation_context(history, topic, user_message)

    # Generate response with learning style adaptation
    response_prompt = generate_follow_up_text_prompt(chapter, topic, conversation_context, user_message, learning_style, difficulty)

    begin
      response_text = openai_service.generate_simple_text(response_prompt)

      result = {
        success: true,
        response: response_text,
        should_generate_image: should_generate_image
      }

      # Generate new image if needed
      if should_generate_image
        image_prompt = generate_follow_up_image_prompt(chapter, topic, user_message, history, learning_style, difficulty)
        image_url = openai_service.generate_image(image_prompt)
        result[:image_url] = image_url
      end

      result
    rescue => e
      {
        success: false,
        error: e.message,
        response: "Sorry, I encountered an error. Please try again.",
        should_generate_image: false
      }
    end
  end

  def generate_image_prompt(chapter, topic, learning_style, difficulty, interaction_type)
    # Extract grade level from chapter
    grade_level = chapter.subject.grade.name.gsub(/[^\d]/, '').to_i
    grade_level = grade_level > 0 ? grade_level : 10 # Default to grade 10 if can't parse

    # Determine age group based on grade
    age_group = case grade_level
    when 1..5 then "7-11"
    when 6..8 then "12-14"
    when 9..12 then "15-18"
    else "15-18"
    end

    # Determine style based on age group and learning style
    style = determine_visual_style(age_group, learning_style, difficulty)

    # Generate the concept based on topic, chapter, and learning style
    concept = generate_visual_concept(topic, chapter, learning_style, difficulty, interaction_type)

    # Create the improved prompt template
    <<~PROMPT
      Create a visually engaging and educational illustration for a #{age_group}-year-old student learning #{chapter.subject.name}.
      The topic is: #{topic}.
      Learning style: #{learning_style}
      Difficulty level: #{difficulty}
      Interaction type: #{interaction_type}
      Concept to visualize: #{concept}.

      Focus on a clear, visual explanation of the concept without using any text or labels in the image.
      Use a #{style} style.
      The image should help the student understand the concept just by looking at it, like a visual metaphor or diagram.

      Do not include any words, labels, or writing in the image.
      Use layout, shapes, characters, or objects to make the idea intuitive and memorable.
      Make it colorful, simple, and focused on the core idea — avoid clutter or extra decoration.
    PROMPT
  end

  def generate_follow_up_image_prompt(chapter, topic, user_message, history, learning_style, difficulty)
    # Extract grade level from chapter
    grade_level = chapter.subject.grade.name.gsub(/[^\d]/, '').to_i
    grade_level = grade_level > 0 ? grade_level : 10

    # Determine age group based on grade
    age_group = case grade_level
    when 1..5 then "7-11"
    when 6..8 then "12-14"
    when 9..12 then "15-18"
    else "15-18"
    end

    # Determine style based on age group and learning style
    style = determine_visual_style(age_group, learning_style, difficulty)

    # Generate follow-up concept based on user question
    follow_up_concept = generate_follow_up_visual_concept(topic, user_message, history, learning_style, difficulty)

    # Create the improved follow-up prompt template
    <<~PROMPT
      Create a visually engaging and educational illustration for a #{age_group}-year-old student learning #{chapter.subject.name}.
      The topic is: #{topic}.
      Learning style: #{learning_style}
      Difficulty level: #{difficulty}
      Concept to visualize: #{follow_up_concept}.

      Focus on a clear, visual explanation of the concept without using any text or labels in the image.
      Use a #{style} style.
      The image should help the student understand the concept just by looking at it, like a visual metaphor or diagram.

      Do not include any words, labels, or writing in the image.
      Use layout, shapes, characters, or objects to make the idea intuitive and memorable.
      Make it colorful, simple, and focused on the core idea — avoid clutter or extra decoration.
    PROMPT
  end

  def generate_text_prompt(chapter, topic, learning_style, difficulty, interaction_type)
    grade_level = chapter.subject.grade.name.gsub(/[^\d]/, '').to_i
    grade_level = grade_level > 0 ? grade_level : 10

    # Adapt explanation style based on learning style
    style_adaptation = case learning_style
    when 'Visual'
      "Use vivid visual language and descriptive imagery. Include phrases like 'imagine you can see' and 'picture this'."
    when 'Kinesthetic'
      "Use action-oriented language and hands-on examples. Include phrases like 'try this' and 'move your hands'."
    when 'Auditory'
      "Use rhythmic language and sound-related metaphors. Include phrases like 'listen to this' and 'hear how'."
    when 'Reading/Writing'
      "Use structured, detailed explanations with clear organization. Include phrases like 'let's break this down' and 'here's the structure'."
    else
      "Use clear, engaging language that appeals to multiple learning styles."
    end

    # Adapt complexity based on difficulty
    complexity_adaptation = case difficulty
    when 'Beginner'
      "Use simple language and basic concepts. Start with fundamentals and build gradually."
    when 'Intermediate'
      "Use moderate complexity with some challenging concepts. Include both basic and advanced elements."
    when 'Advanced'
      "Use sophisticated language and complex concepts. Assume prior knowledge and build on it."
    else
      "Use appropriate complexity for the grade level."
    end

    # Adapt interaction type
    interaction_adaptation = case interaction_type
    when 'Exploration'
      "Encourage curiosity and discovery. Ask open-ended questions and suggest further exploration."
    when 'Practice'
      "Include practical examples and exercises. Provide step-by-step guidance for hands-on learning."
    when 'Assessment'
      "Include self-check questions and reflection points. Help students evaluate their understanding."
    when 'Review'
      "Summarize key points and connect to previous knowledge. Reinforce important concepts."
    else
      "Provide a balanced approach to learning."
    end

    <<~PROMPT
      You are an expert teacher explaining #{topic} from the chapter "#{chapter.name}" in #{chapter.subject.name} for Grade #{grade_level} students.

      Learning Style: #{learning_style}
      Difficulty Level: #{difficulty}
      Interaction Type: #{interaction_type}

      Please provide a clear, engaging explanation that:
      1. #{style_adaptation}
      2. #{complexity_adaptation}
      3. #{interaction_adaptation}
      4. Starts with a simple, relatable example
      5. Uses analogies and visual language
      6. Breaks down complex concepts into digestible parts
      7. Includes practical applications
      8. Encourages curiosity and further questions

      Make it conversational and suitable for students. Keep it under 300 words.
    PROMPT
  end

  def generate_follow_up_text_prompt(chapter, topic, conversation_context, user_message, learning_style, difficulty)
    # Adapt response style based on learning style
    style_adaptation = case learning_style
    when 'Visual'
      "Use visual language and imagery in your response."
    when 'Kinesthetic'
      "Include action-oriented examples and hands-on activities."
    when 'Auditory'
      "Use rhythmic language and sound-related metaphors."
    when 'Reading/Writing'
      "Provide structured, detailed explanations with clear organization."
    else
      "Use clear, engaging language."
    end

    # Adapt complexity based on difficulty
    complexity_adaptation = case difficulty
    when 'Beginner'
      "Keep explanations simple and fundamental."
    when 'Intermediate'
      "Include moderate complexity with some challenging concepts."
    when 'Advanced'
      "Use sophisticated language and complex concepts."
    else
      "Use appropriate complexity for the grade level."
    end

    <<~PROMPT
      You are continuing a conversation about #{topic} from the chapter "#{chapter.name}" in #{chapter.subject.name}.

      Learning Style: #{learning_style}
      Difficulty Level: #{difficulty}

      Previous conversation:
      #{conversation_context}

      Student's latest question: #{user_message}

      Please provide a helpful, educational response that:
      1. #{style_adaptation}
      2. #{complexity_adaptation}
      3. Addresses the student's specific question
      4. Builds on previous explanations
      5. Uses clear, simple language
      6. Encourages deeper understanding
      7. Is conversational and engaging

      Keep your response under 200 words.
    PROMPT
  end

  def determine_visual_style(age_group, learning_style, difficulty)
    base_style = case age_group
    when "7-11" then "cartoonish and playful"
    when "12-14" then "clean and engaging"
    else "realistic and professional"
    end

    # Adapt based on learning style
    style_adaptation = case learning_style
    when 'Visual' then "with strong visual elements and clear imagery"
    when 'Kinesthetic' then "with action-oriented elements and movement"
    when 'Auditory' then "with flowing, dynamic elements"
    when 'Reading/Writing' then "with structured, organized elements"
    else ""
    end

    # Adapt based on difficulty
    difficulty_adaptation = case difficulty
    when 'Beginner' then "simple and straightforward"
    when 'Intermediate' then "with moderate complexity"
    when 'Advanced' then "with sophisticated elements"
    else ""
    end

    "#{base_style} #{style_adaptation} #{difficulty_adaptation}".strip
  end

  def generate_visual_concept(topic, chapter, learning_style, difficulty, interaction_type)
    # Base visual concept
    base_concept = case topic.downcase
    when /triangle/
      "Visualize triangles as colorful building blocks with three sides, showing how they fit together like puzzle pieces"
    when /circle/
      "Visualize circles as round objects like wheels or coins, with a center point and equal distance to all edges"
    when /square/
      "Visualize squares as perfect boxes with four equal sides, like building blocks or tiles"
    when /photo/
      "Visualize photosynthesis as a plant growing taller with sunlight rays, like a plant reaching for the sun"
    when /cell/
      "Visualize cells as tiny rooms with different parts like a factory, each part having a specific job"
    when /force/
      "Visualize forces as invisible hands pushing and pulling objects, like magnets or wind moving things"
    when /energy/
      "Visualize energy as flowing light or power, like electricity flowing through wires or heat rising"
    when /motion/
      "Visualize motion as objects moving through space, like a ball rolling or a car driving"
    when /molecule/
      "Visualize molecules as connected balls or beads, like a necklace where each bead represents an atom"
    when /reaction/
      "Visualize chemical reactions as ingredients mixing and changing, like cooking where things transform"
    when /ecosystem/
      "Visualize ecosystems as a web of connections, like a garden where plants, animals, and weather all work together"
    when /econom/
      "Visualize economics as people trading objects, like a marketplace where goods are exchanged"
    when /math/
      "Visualize math as patterns and shapes that solve problems, like a puzzle where numbers fit together"
    when /algebra/
      "Visualize algebra as finding missing pieces, like a detective solving a mystery with clues"
    when /geometry/
      "Visualize geometry as shapes and their properties, like a toolbox of different shaped tools"
    when /calculus/
      "Visualize calculus as understanding how things change over time, like watching a plant grow or water flow"
    when /statistics/
      "Visualize statistics as organizing information into groups, like sorting toys into different boxes"
    when /probability/
      "Visualize probability as predicting what might happen, like guessing which way a coin will land"
    when /chemistry/
      "Visualize chemistry as tiny building blocks combining, like LEGO pieces that can be taken apart and rebuilt"
    when /physics/
      "Visualize physics as the rules that make the world work, like invisible forces that control everything"
    when /biology/
      "Visualize biology as living things and how they work, like a machine made of many small parts"
    else
      "Visualize #{topic} as a clear, simple concept that can be understood through shapes, colors, and objects"
    end

    # Adapt based on learning style
    style_adaptation = case learning_style
    when 'Visual' then "with strong visual elements and clear imagery"
    when 'Kinesthetic' then "with action-oriented elements and movement"
    when 'Auditory' then "with flowing, dynamic elements"
    when 'Reading/Writing' then "with structured, organized elements"
    else ""
    end

    # Adapt based on difficulty
    difficulty_adaptation = case difficulty
    when 'Beginner' then "in a simple, straightforward way"
    when 'Intermediate' then "with moderate complexity"
    when 'Advanced' then "with sophisticated elements"
    else ""
    end

    # Adapt based on interaction type
    interaction_adaptation = case interaction_type
    when 'Exploration' then "encouraging discovery and curiosity"
    when 'Practice' then "with hands-on, practical elements"
    when 'Assessment' then "with clear evaluation points"
    when 'Review' then "reinforcing key concepts"
    else ""
    end

    "#{base_concept} #{style_adaptation} #{difficulty_adaptation} #{interaction_adaptation}".strip
  end

  def generate_follow_up_visual_concept(topic, user_message, history, learning_style, difficulty)
    # Generate visual metaphors for follow-up questions
    base_concept = case user_message.downcase
    when /show|picture|visual|diagram/
      "Visualize #{topic} as a clear picture that shows the main idea through shapes and colors"
    when /how|explain/
      "Visualize #{topic} as a step-by-step process, like a story with a beginning, middle, and end"
    when /what|define/
      "Visualize #{topic} as its core parts or pieces, like taking apart a toy to see how it works"
    when /compare|difference/
      "Visualize #{topic} as two or more things side by side, showing how they are similar or different"
    when /process|steps/
      "Visualize #{topic} as a journey or path, like following a map from start to finish"
    when /example|instance/
      "Visualize #{topic} as a real-world example, like seeing the concept in everyday life"
    when /why|reason/
      "Visualize #{topic} as cause and effect, like dominoes falling or a chain reaction"
    when /when|time/
      "Visualize #{topic} as a timeline or sequence, like watching a movie frame by frame"
    when /where|location/
      "Visualize #{topic} as a map or space, like seeing where things are in relation to each other"
    else
      "Visualize #{topic} as a clear, simple concept that can be understood through shapes, colors, and objects"
    end

    # Adapt based on learning style and difficulty
    style_adaptation = case learning_style
    when 'Visual' then "with strong visual elements"
    when 'Kinesthetic' then "with action-oriented elements"
    when 'Auditory' then "with flowing, dynamic elements"
    when 'Reading/Writing' then "with structured, organized elements"
    else ""
    end

    difficulty_adaptation = case difficulty
    when 'Beginner' then "in a simple way"
    when 'Intermediate' then "with moderate complexity"
    when 'Advanced' then "with sophisticated elements"
    else ""
    end

    "#{base_concept} #{style_adaptation} #{difficulty_adaptation}".strip
  end

  def should_generate_new_image?(history, user_message)
    # Don't generate image for every message
    return false if history.length < 2

    # Generate image for:
    # 1. New subtopics or concepts
    # 2. Visual explanations requested
    # 3. Every 3-4 messages
    # 4. When user asks for visual help

    visual_keywords = ['show', 'picture', 'visual', 'diagram', 'draw', 'see', 'look']
    has_visual_request = visual_keywords.any? { |keyword| user_message.downcase.include?(keyword) }

    # Generate image every 3 messages or when explicitly requested
    (history.length % 3 == 0) || has_visual_request
  end

  def build_conversation_context(history, topic, user_message)
    context_parts = []

    history.each_with_index do |entry, index|
      context_parts << "Exchange #{index + 1}:"
      context_parts << "Student: #{entry[:user_message]}" if entry[:user_message]
      context_parts << "Teacher: #{entry[:ai_response]}" if entry[:ai_response]
      context_parts << ""
    end

    context_parts.join("\n")
  end

  def generate_test_scenarios
    [
      {
        name: "Basic Visual Learning",
        description: "Test fundamental visual explanation generation",
        params: { learning_style: 'Visual', difficulty: 'Beginner', interaction_type: 'Exploration' }
      },
      {
        name: "Kinesthetic Learning",
        description: "Test action-oriented explanations for hands-on learners",
        params: { learning_style: 'Kinesthetic', difficulty: 'Intermediate', interaction_type: 'Practice' }
      },
      {
        name: "Advanced Auditory Learning",
        description: "Test sophisticated explanations for auditory learners",
        params: { learning_style: 'Auditory', difficulty: 'Advanced', interaction_type: 'Assessment' }
      },
      {
        name: "Reading/Writing Style",
        description: "Test structured explanations for reading/writing learners",
        params: { learning_style: 'Reading/Writing', difficulty: 'Intermediate', interaction_type: 'Review' }
      },
      {
        name: "Cross-Style Comparison",
        description: "Compare the same topic across different learning styles",
        params: { difficulty: 'Beginner', interaction_type: 'Exploration' }
      }
    ]
  end

  def run_performance_tests
    {
      image_generation_time: measure_image_generation_time,
      text_generation_time: measure_text_generation_time,
      concurrent_requests: test_concurrent_requests,
      error_rate: calculate_error_rate,
      memory_usage: measure_memory_usage
    }
  end

  def measure_image_generation_time
    start_time = Time.now
    service = OpenaiService.new
    result = service.generate_image("Simple test image")
    end_time = Time.now
    (end_time - start_time).round(2)
  end

  def measure_text_generation_time
    start_time = Time.now
    service = OpenaiService.new
    result = service.generate_simple_text("Simple test explanation")
    end_time = Time.now
    (end_time - start_time).round(2)
  end

  def test_concurrent_requests
    # Simulate concurrent requests
    threads = []
    results = []

    5.times do |i|
      threads << Thread.new do
        begin
          service = OpenaiService.new
          result = service.generate_simple_text("Test #{i}")
          results << { success: true, thread: i }
        rescue => e
          results << { success: false, thread: i, error: e.message }
        end
      end
    end

    threads.each(&:join)
    results
  end

  def calculate_error_rate
    # Calculate error rate from recent requests
    total_requests = 100
    successful_requests = 95 # Mock data
    (total_requests - successful_requests).to_f / total_requests * 100
  end

  def measure_memory_usage
    # Mock memory usage measurement
    {
      current: "150MB",
      peak: "200MB",
      average: "175MB"
    }
  end
end
