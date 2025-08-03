class OpenaiService
  include HTTParty

  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  # Generate answer for a question using RAG
  def generate_answer(question, chapter, context_chunks = [])
    prompt = build_rag_prompt(question, chapter, context_chunks)

    begin
      response = @client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            { role: "system", content: "You are a friendly, patient math tutor who explains concepts in simple, engaging ways.

EXPLANATION GUIDELINES:
- ALWAYS provide real-world examples that students can relate to (cooking, sports, money, games, etc.)
- Use analogies and comparisons that make abstract concepts concrete
- Break down complex concepts into simple, digestible steps
- Use visual language and descriptive examples
- Make connections to everyday life situations
- Ensure the student understands by asking comprehension check questions
- If a concept is unclear, provide multiple examples from different angles
- Use storytelling techniques to make explanations memorable
- Connect mathematical concepts to practical applications

STYLE GUIDELINES:
- Use conversational, friendly language (like talking to a friend)
- Include practical, real-world examples
- Break down complex concepts into simple steps
- Use analogies and comparisons students can relate to
- Keep explanations concise (max 3-4 paragraphs)
- Avoid asterisks (*) and formal formatting
- Use bullet points or numbered steps when helpful
- End every response with a follow-up question like: 'Would you like me to explain more about this topic, or do you have any other questions?'" },
            { role: "user", content: prompt }
          ],
          max_tokens: 1000,
          temperature: 0.8
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"

      # Check if it's an API key issue
      if e.message.include?("401") || e.message.include?("authentication")
        "I'm sorry, there's an issue with the AI service configuration. Please contact support."
      elsif e.message.include?("400")
        "I'm sorry, there's an issue with the AI service request. Please try again with a different question."
      else
        "I'm sorry, I'm having trouble processing your question right now. Please try again later."
      end
    end
  end

  # Generate answer with conversation history context
  def generate_answer_with_history(question, chapter, context_chunks = [], conversation_history = [])
    prompt = build_rag_prompt_with_history(question, chapter, context_chunks, conversation_history)

    begin
      # Build messages array with conversation history
      messages = [
        { role: "system", content: "You are a friendly, patient math tutor who explains concepts in simple, engaging ways.

IMPORTANT CONVERSATION RULES:
- ALWAYS reference previous parts of our conversation when relevant
- If the student says 'can't understand', 'explain again', or similar, ask SPECIFIC follow-up questions like: 'What part specifically is unclear? Is it the prime factorization, the proof by contradiction, or something else?'
- If they ask 'yes' or 'no' questions, provide clear yes/no answers with explanations
- If they ask 'what else' or 'and', expand on the current topic or suggest related topics
- If they say 'hey' or similar greetings, acknowledge the greeting and ask how you can help
- Build upon previous explanations instead of repeating the same content
- Use the conversation history to provide more targeted, contextual responses

EXPLANATION GUIDELINES:
- ALWAYS provide real-world examples that students can relate to (cooking, sports, money, games, etc.)
- Use analogies and comparisons that make abstract concepts concrete
- Break down complex concepts into simple, digestible steps
- Use visual language and descriptive examples
- Make connections to everyday life situations
- Ensure the student understands by asking comprehension check questions
- If a concept is unclear, provide multiple examples from different angles
- Use storytelling techniques to make explanations memorable
- Connect mathematical concepts to practical applications

STYLE GUIDELINES:
- Use conversational, friendly language (like talking to a friend)
- Include practical, real-world examples
- Break down complex concepts into simple steps
- Use analogies and comparisons students can relate to
- Keep explanations concise (max 3-4 paragraphs)
- Avoid asterisks (*) and formal formatting
- Use bullet points or numbered steps when helpful

ALWAYS end with a relevant follow-up question based on the conversation context." }
      ]

      # Add conversation history to messages
      conversation_history.each do |qa_pair|
        messages << { role: "user", content: qa_pair[:question] }
        messages << { role: "assistant", content: qa_pair[:answer] }
      end

      # Add current question
      messages << { role: "user", content: prompt }

      response = @client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: messages,
          max_tokens: 1000,
          temperature: 0.8
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"

      # Check if it's an API key issue
      if e.message.include?("401") || e.message.include?("authentication")
        "I'm sorry, there's an issue with the AI service configuration. Please contact support."
      elsif e.message.include?("400")
        "I'm sorry, there's an issue with the AI service request. Please try again with a different question."
      else
        "I'm sorry, I'm having trouble processing your question right now. Please try again later."
      end
    end
  end

  # Generate embeddings for text chunks
  def generate_embedding(text)
    response = @client.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: text
      }
    )

    response.dig("data", 0, "embedding")
  rescue => e
    Rails.logger.error "OpenAI Embedding Error: #{e.message}"
    nil
  end

  # Generate chapter explanation
  def generate_chapter_explanation(chapter)
    prompt = "Explain #{chapter.display_name} in a friendly, conversational way that students will love! Include:
- Simple, everyday examples they can relate to
- Step-by-step breakdowns of key concepts
- Fun analogies or comparisons
- Why this topic matters in real life
- Keep it concise (2-3 paragraphs max)
- End with a follow-up question to encourage learning"

    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: "You are an enthusiastic, friendly teacher who makes learning fun and accessible. Use conversational language, include relatable examples, and make students excited about learning. Keep responses concise and end with follow-up questions." },
          { role: "user", content: prompt }
        ],
        max_tokens: 1000,
        temperature: 0.8
      }
    )

    response.dig("choices", 0, "message", "content")
  rescue => e
    Rails.logger.error "OpenAI Chapter Explanation Error: #{e.message}"
    "I'm sorry, I'm having trouble generating the chapter explanation right now. Please try again later."
  end

  private

  def build_rag_prompt(question, chapter, context_chunks)
    context_text = context_chunks.map(&:content).join("\n\n")

    if context_text.present?
      "Based on the following textbook content for #{chapter.display_name}:\n\n#{context_text}\n\nStudent Question: #{question}\n\nIMPORTANT INSTRUCTIONS:\n1. Use the textbook content as a foundation, but feel free to add your own relevant examples and analogies\n2. ALWAYS provide real-world examples that students can relate to (cooking, sports, money, games, etc.)\n3. Use storytelling and analogies to make concepts memorable\n4. Break down complex ideas into simple, digestible steps\n5. Ensure the student understands by providing multiple perspectives\n6. Connect mathematical concepts to practical, everyday situations\n7. If the concept is unclear, provide examples from different angles\n\nPlease explain this in a friendly, conversational way. Keep it concise (2-3 paragraphs max) with practical examples. Avoid asterisks (*) and formal formatting. End with a follow-up question to encourage continued learning."
    else
      "Student Question about #{chapter.display_name}: #{question}\n\nIMPORTANT INSTRUCTIONS:\n1. Provide comprehensive explanations even without textbook content\n2. ALWAYS include real-world examples that students can relate to (cooking, sports, money, games, etc.)\n3. Use analogies and comparisons to make abstract concepts concrete\n4. Break down complex ideas into simple, digestible steps\n5. Use storytelling techniques to make explanations memorable\n6. Connect mathematical concepts to practical applications\n7. Ensure understanding by providing multiple perspectives\n\nPlease explain this concept in a friendly, conversational way with practical examples. Keep it concise (2-3 paragraphs max). Avoid asterisks (*) and formal formatting. End with a follow-up question to encourage continued learning."
    end
  end

  def build_rag_prompt_with_history(question, chapter, context_chunks, conversation_history)
    context_text = context_chunks.map(&:content).join("\n\n")

    # Build conversation context summary
    conversation_summary = ""
    if conversation_history.any?
      conversation_summary = "\n\nCONVERSATION CONTEXT: We've been discussing #{chapter.display_name}. "
      conversation_summary += "Previous topics covered: " + conversation_history.map { |qa| qa[:question].split(' ').first(5).join(' ') }.join(', ')
      conversation_summary += "\n\nIMPORTANT: If the student's question relates to our previous conversation, explicitly reference that context and build upon it. If they say 'can't understand' or 'explain again', ask specific follow-up questions about what part is unclear."
    end

    if context_text.present?
      "Based on the following textbook content for #{chapter.display_name}:\n\n#{context_text}#{conversation_summary}\n\nStudent Question: #{question}\n\nIMPORTANT INSTRUCTIONS:\n1. Use the textbook content as a foundation, but feel free to add your own relevant examples and analogies\n2. ALWAYS provide real-world examples that students can relate to (cooking, sports, money, games, etc.)\n3. Use storytelling and analogies to make concepts memorable\n4. Break down complex ideas into simple, digestible steps\n5. Ensure the student understands by providing multiple perspectives\n6. Connect mathematical concepts to practical, everyday situations\n7. If the concept is unclear, provide examples from different angles\n\nPlease explain this in a friendly, conversational way. Keep it concise (2-3 paragraphs max) with practical examples. Avoid asterisks (*) and formal formatting. If this is a follow-up question, reference our previous discussion. If they ask a yes/no question, provide a clear yes/no answer with explanation. End with a relevant follow-up question based on the conversation context."
    else
      "Student Question about #{chapter.display_name}:#{conversation_summary}\n\n#{question}\n\nIMPORTANT INSTRUCTIONS:\n1. Provide comprehensive explanations even without textbook content\n2. ALWAYS include real-world examples that students can relate to (cooking, sports, money, games, etc.)\n3. Use analogies and comparisons to make abstract concepts concrete\n4. Break down complex ideas into simple, digestible steps\n5. Use storytelling techniques to make explanations memorable\n6. Connect mathematical concepts to practical applications\n7. Ensure understanding by providing multiple perspectives\n\nPlease explain this concept in a friendly, conversational way with practical examples. Keep it concise (2-3 paragraphs max). Avoid asterisks (*) and formal formatting. If this is a follow-up question, reference our previous discussion. If they ask a yes/no question, provide a clear yes/no answer with explanation. End with a relevant follow-up question based on the conversation context."
    end
  end
end
