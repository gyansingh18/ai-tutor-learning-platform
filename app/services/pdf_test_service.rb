class PdfTestService
  def initialize
    @pdf_directory = Rails.root.join('app', 'assets', 'pdfs')
  end

  def test_pdf_reading
    puts "🔍 Testing PDF Reading Capabilities..."
    puts "📁 PDF Directory: #{@pdf_directory}"

    # Test reading each PDF
    Dir.glob(File.join(@pdf_directory, '**/*.pdf')).each do |pdf_path|
      puts "\n" + "="*60
      puts "📄 Testing: #{File.basename(pdf_path)}"
      puts "📍 Path: #{pdf_path}"

      test_single_pdf(pdf_path)
    end
  end

  def test_single_pdf(pdf_path)
    begin
      # Read PDF
      pdf = PDF::Reader.new(pdf_path)

      # Extract basic information
      basic_info = extract_basic_info(pdf, pdf_path)
      puts "📊 Basic Info:"
      puts "   - Pages: #{basic_info[:page_count]}"
      puts "   - File Size: #{basic_info[:file_size]}"
      puts "   - PDF Version: #{basic_info[:version]}"

      # Extract text sample
      text_sample = extract_text_sample(pdf)
      puts "📝 Text Sample (first 500 chars):"
      puts "   #{text_sample[0..500]}..."

      # Extract chapter information
      chapter_info = extract_chapter_info(pdf_path, text_sample)
      puts "📚 Chapter Info:"
      puts "   - Chapter Name: #{chapter_info[:chapter_name]}"
      puts "   - Subject: #{chapter_info[:subject]}"
      puts "   - Grade: #{chapter_info[:grade]}"
      puts "   - Description: #{chapter_info[:description]}"

      # Test AI extraction
      ai_info = extract_with_ai(text_sample)
      puts "🤖 AI Analysis:"
      puts "   - AI Chapter Name: #{ai_info[:chapter_name]}"
      puts "   - AI Description: #{ai_info[:description]}"
      puts "   - AI Topics: #{ai_info[:topics]}"

      # Test content analysis
      content_analysis = analyze_content(text_sample)
      puts "📈 Content Analysis:"
      puts "   - Word Count: #{content_analysis[:word_count]}"
      puts "   - Reading Level: #{content_analysis[:reading_level]}"
      puts "   - Technical Terms: #{content_analysis[:technical_terms]}"

    rescue => e
      puts "❌ Error reading PDF: #{e.message}"
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
