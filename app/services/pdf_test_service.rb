class PdfTestService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || "pdfs"  # Changed from local path to S3 prefix
  end

  def test_pdf_reading
    puts "🔍 Testing PDF Reading Capabilities (S3)"
    puts "📁 PDF Directory: #{@pdf_directory}"

    # Test reading PDFs from S3
    pdfs = S3PdfService.list_pdfs_by_prefix(@pdf_directory)

    if pdfs.any?
      puts "📊 Found #{pdfs.count} PDFs in S3"

      # Test first few PDFs
      pdfs.first(3).each do |pdf_key|
        puts "📄 Testing: #{File.basename(pdf_key)}"
        puts "📍 S3 Key: #{pdf_key}"

        test_single_pdf_from_s3(pdf_key)
        puts "---"
      end
    else
      puts "⚠️  No PDFs found in S3"
    end
  end

  def test_single_pdf_from_s3(pdf_key)
    begin
      # Download PDF from S3 temporarily
      temp_file = download_pdf_from_s3(pdf_key)

      # Read PDF
      pdf = PDF::Reader.new(temp_file.path)

      basic_info = extract_basic_info_from_s3(pdf, pdf_key)
      puts "   ✅ PDF Version: #{basic_info[:version]}"
      puts "   📄 Page Count: #{basic_info[:page_count]}"
      puts "   📏 File Size: #{basic_info[:file_size]}"

      text_sample = extract_text_sample(pdf)
      chapter_info = extract_chapter_info_from_s3(pdf_key, text_sample)

      puts "   📚 Chapter: #{chapter_info[:chapter_name]}"
      puts "   🎯 Subject: #{chapter_info[:subject]}"
      puts "   📖 Grade: #{chapter_info[:grade]}"

      # Clean up temp file
      temp_file.close
      temp_file.unlink

    rescue => e
      puts "   ❌ Error reading PDF from S3: #{e.message}"
    end
  end

  def download_pdf_from_s3(pdf_key)
    require 'tempfile'

    # Create temporary file
    temp_file = Tempfile.new(['pdf', '.pdf'])

    # Download from S3
    S3_CLIENT.get_object(
      bucket: S3_BUCKET,
      key: pdf_key,
      response_target: temp_file.path
    )

    temp_file
  end

  def extract_basic_info_from_s3(pdf, pdf_key)
    {
      page_count: pdf.page_count,
      file_size: "#{(get_s3_file_size(pdf_key) / 1024.0).round(2)} KB",
      version: pdf.pdf_version,
      info: pdf.info,
      metadata: pdf.metadata
    }
  end

  def get_s3_file_size(pdf_key)
    resp = S3_CLIENT.head_object(bucket: S3_BUCKET, key: pdf_key)
    resp.content_length
  end

  def extract_chapter_info_from_s3(pdf_key, text_sample)
    # Extract info from S3 key path
    path_parts = pdf_key.split('/')

    if path_parts.length >= 3
      grade = path_parts[1]&.gsub('class_', 'Grade ')
      subject = path_parts[2]&.capitalize
      filename = File.basename(pdf_key, '.pdf')

      {
        chapter_name: filename,
        subject: subject,
        grade: grade,
        text_sample: text_sample[0..200]
      }
    else
      {
        chapter_name: File.basename(pdf_key, '.pdf'),
        subject: 'Unknown',
        grade: 'Unknown',
        text_sample: text_sample[0..200]
      }
    end
  end

  private

  def extract_basic_info(pdf, pdf_path)
    {
      page_count: pdf.page_count,
      file_size: "#{(File.size(pdf_path) / 1024.0).round(2)} KB",
      version: pdf.pdf_version,
      info: pdf.info,
      metadata: pdf.metadata
    }
  end

  def extract_text_sample(pdf)
    text = ""
    # Read first 3 pages for sample
    pdf.pages.first(3).each_with_index do |page, index|
      text += "=== PAGE #{index + 1} ===\n"
      text += page.text + "\n\n"
    end
    text
  end

  def extract_chapter_info(pdf_path, text_sample)
    # Extract from file path
    path_parts = pdf_path.split('/')
    grade_part = path_parts.find { |part| part.start_with?('class_') }
    subject_part = path_parts.find { |part| ['mathematics', 'science', 'english'].include?(part) }
    filename = File.basename(pdf_path, '.pdf')

    # Extract chapter name from filename
    chapter_name = filename
      .gsub(/^chapter_\d+_/, '')
      .gsub(/_/, ' ')
      .split(' ')
      .map(&:capitalize)
      .join(' ')

    {
      chapter_name: chapter_name,
      subject: subject_part&.capitalize,
      grade: grade_part&.gsub('class_', 'Grade '),
      description: "Chapter covering #{chapter_name.downcase} concepts."
    }
  end

  def extract_with_ai(text_sample)
    begin
      openai_service = OpenaiService.new

      prompt = <<~PROMPT
        Analyze this textbook content and extract:
        1. Chapter name/title
        2. Brief description (1-2 sentences)
        3. Main topics covered (comma-separated)

        Content:
        #{text_sample[0..1500]}

        Respond in JSON format:
        {
          "chapter_name": "Chapter Name",
          "description": "Brief description",
          "topics": "topic1, topic2, topic3"
        }
      PROMPT

      # Use a dummy chapter for the method call
      dummy_chapter = Chapter.first || Chapter.new(name: "Test Chapter")
      response = openai_service.generate_answer(prompt, dummy_chapter)

      # Try to parse JSON response
      begin
        parsed = JSON.parse(response)
        {
          chapter_name: parsed['chapter_name'],
          description: parsed['description'],
          topics: parsed['topics']
        }
      rescue JSON::ParserError
        # Fallback if JSON parsing fails
        {
          chapter_name: "Extracted from AI",
          description: response[0..100] + "...",
          topics: "AI analysis available"
        }
      end

    rescue => e
      {
        chapter_name: "AI extraction failed",
        description: "Error: #{e.message}",
        topics: "N/A"
      }
    end
  end

  def analyze_content(text)
    words = text.split(/\s+/)
    sentences = text.split(/[.!?]+/).count

    # Simple reading level calculation (Flesch-Kincaid)
    syllables = text.downcase.scan(/[aeiouy]+/).count
    reading_level = sentences > 0 ? (0.39 * (words.count.to_f / sentences)) + (11.8 * (syllables.to_f / words.count)) - 15.59 : 0

    # Count technical terms (words with capital letters)
    technical_terms = text.scan(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b/).count

    {
      word_count: words.count,
      sentence_count: sentences,
      reading_level: reading_level.round(1),
      technical_terms: technical_terms,
      vocabulary_diversity: words.uniq.count.to_f / words.count
    }
  end
end
