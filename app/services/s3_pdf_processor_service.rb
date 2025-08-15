class S3PdfProcessorService
  def initialize(pdf_material)
    @pdf_material = pdf_material
    @openai_service = OpenaiService.new
  end

  def process
    return false unless @pdf_material.file_path.present?

    # Extract text from PDF in S3
    text_content = extract_text_from_s3_pdf

    # Split text into chunks
    chunks = split_text_into_chunks(text_content)

    # Create vector chunks
    create_vector_chunks(chunks)

    true
  rescue => e
    Rails.logger.error "S3 PDF Processing Error: #{e.message}"
    puts "Error processing PDF #{@pdf_material.file_path}: #{e.message}"
    false
  end

  private

  def extract_text_from_s3_pdf
    begin
      # Download PDF from S3
      resp = S3_CLIENT.get_object(bucket: S3_BUCKET, key: @pdf_material.file_path)
      pdf_data = resp.body.read
      
      # Extract text from PDF
      pdf = PDF::Reader.new(StringIO.new(pdf_data))
      text = ""

      pdf.pages.each do |page|
        text += page.text + "\n"
      end

      text
    rescue => e
      Rails.logger.error "Error downloading PDF from S3: #{e.message}"
      raise e
    end
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
    # Clear existing vector chunks for this PDF material
    @pdf_material.vector_chunks.destroy_all
    
    chunks.each_with_index do |chunk, index|
      begin
        # Generate embedding
        embedding = @openai_service.generate_embedding(chunk)
        next unless embedding

        # Create vector chunk
        vector_chunk = @pdf_material.vector_chunks.build(
          chapter: @pdf_material.chapter,
          content: chunk,
          embedding: embedding.to_json,
          chunk_index: index
        )

        vector_chunk.save!
      rescue => e
        Rails.logger.error "Error creating vector chunk #{index}: #{e.message}"
        puts "  Error creating vector chunk #{index}: #{e.message}"
      end
    end
    
    puts "  Created #{@pdf_material.vector_chunks.count} vector chunks"
  end
end
