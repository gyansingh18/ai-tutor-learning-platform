class PdfProcessorService
  def initialize(pdf_material)
    @pdf_material = pdf_material
    @openai_service = OpenaiService.new
  end

  def process
    return false unless @pdf_material.pdf_file.attached?

    # Extract text from PDF
    text_content = extract_text_from_pdf

    # Split text into chunks
    chunks = split_text_into_chunks(text_content)

    # Create vector chunks
    create_vector_chunks(chunks)

    true
  rescue => e
    Rails.logger.error "PDF Processing Error: #{e.message}"
    false
  end

  private

  def extract_text_from_pdf
    pdf = PDF::Reader.new(StringIO.new(@pdf_material.pdf_file.download))
    text = ""

    pdf.pages.each do |page|
      text += page.text + "\n"
    end

    text
  end

  def split_text_into_chunks(text, chunk_size = 1000, overlap = 200)
    chunks = []
    words = text.split(/\s+/)

    i = 0
    while i < words.length
      chunk_words = words[i, chunk_size]
      chunks << chunk_words.join(" ")
      i += chunk_size - overlap
    end

    chunks.reject(&:blank?)
  end

  def create_vector_chunks(chunks)
    chunks.each do |chunk|
      # Generate embedding
      embedding = @openai_service.generate_embedding(chunk)
      next unless embedding

      # Create vector chunk
      vector_chunk = @pdf_material.vector_chunks.build(
        chapter: @pdf_material.chapter,
        content: chunk,
        embedding: embedding.to_json
      )

      vector_chunk.save!
    end
  end
end
