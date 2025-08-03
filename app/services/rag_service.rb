class RagService
  def initialize(chapter)
    @chapter = chapter
    @openai_service = OpenaiService.new
  end

  def find_relevant_chunks(question, limit = 5)
    # Generate embedding for the question
    question_embedding = @openai_service.generate_embedding(question)
    return [] unless question_embedding

    # Get all vector chunks for this chapter
    vector_chunks = @chapter.vector_chunks.includes(:pdf_material)

    # Calculate similarities and find top matches
    similarities = vector_chunks.map do |chunk|
      chunk_embedding = chunk.embedding_array
      similarity = cosine_similarity(question_embedding, chunk_embedding)
      [chunk, similarity]
    end

    # Sort by similarity and return top results
    similarities
      .sort_by { |_, similarity| -similarity }
      .first(limit)
      .map { |chunk, _| chunk }
  end

  def answer_question(question, conversation_history = [])
    # Find relevant chunks
    relevant_chunks = find_relevant_chunks(question)

    # Generate answer using OpenAI with conversation history
    @openai_service.generate_answer_with_history(question, @chapter, relevant_chunks, conversation_history)
  end

  private

  def cosine_similarity(vec1, vec2)
    return 0 if vec1.empty? || vec2.empty?

    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    magnitude1 = Math.sqrt(vec1.sum { |x| x**2 })
    magnitude2 = Math.sqrt(vec2.sum { |x| x**2 })

    return 0 if magnitude1.zero? || magnitude2.zero?

    dot_product / (magnitude1 * magnitude2)
  end
end
