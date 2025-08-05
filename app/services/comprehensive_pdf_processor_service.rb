class ComprehensivePdfProcessorService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || Rails.root.join('app', 'assets', 'pdfs')
    @openai_service = OpenaiService.new
  end

  def analyze_all_structure
    puts "🔍 COMPREHENSIVE PDF STRUCTURE ANALYSIS"
    puts "=" * 60

    total_pdfs = 0
    total_chapters = 0

    Dir.glob(File.join(@pdf_directory, '*')).each do |grade_path|
      next unless File.directory?(grade_path)

      grade_name = File.basename(grade_path)
      puts "\n📚 GRADE: #{grade_name.upcase}"
      puts "-" * 40

      grade_pdfs = 0
      grade_chapters = 0

      Dir.glob(File.join(grade_path, '*')).each do |subject_path|
        next unless File.directory?(subject_path)

        subject_name = File.basename(subject_path)
        pdfs = Dir.glob(File.join(subject_path, '**/*.pdf'))

        puts "  📖 #{subject_name.capitalize}: #{pdfs.count} PDFs"

        pdfs.each do |pdf_path|
          puts "    📄 #{File.basename(pdf_path)} (#{File.size(pdf_path) / 1024} KB)"
        end

        grade_pdfs += pdfs.count
        grade_chapters += pdfs.count # Each PDF = 1 chapter
      end

      puts "  📊 Total: #{grade_pdfs} PDFs, #{grade_chapters} potential chapters"
      total_pdfs += grade_pdfs
      total_chapters += grade_chapters
    end

    puts "\n" + "=" * 60
    puts "📊 GRAND TOTAL: #{total_pdfs} PDFs, #{total_chapters} potential chapters"
    puts "=" * 60
  end

  def process_all_classes
    puts "🚀 PROCESSING ALL CLASSES AND SUBJECTS"
    puts "=" * 60

    processed_count = 0
    error_count = 0

    Dir.glob(File.join(@pdf_directory, '*')).each do |grade_path|
      next unless File.directory?(grade_path)

      grade_name = File.basename(grade_path)
      puts "\n📚 Processing Grade: #{grade_name}"

      # Find or create grade
      grade = find_or_create_grade(grade_name)

      Dir.glob(File.join(grade_path, '*')).each do |subject_path|
        next unless File.directory?(subject_path)

        subject_name = File.basename(subject_path)
        puts "  📖 Processing Subject: #{subject_name}"

        # Find or create subject
        subject = find_or_create_subject(subject_name, grade)

        # Process all PDFs in this subject (including subdirectories)
        Dir.glob(File.join(subject_path, '**/*.pdf')).each do |pdf_path|
          puts "    📄 Processing: #{File.basename(pdf_path)}"

          begin
            chapter = process_single_pdf_with_subject(pdf_path, grade, subject)
            if chapter
              processed_count += 1
              puts "      ✅ Created: #{chapter.name}"
            else
              error_count += 1
              puts "      ❌ Failed to process"
            end
          rescue => e
            error_count += 1
            puts "      ❌ Error: #{e.message}"
          end
        end
      end
    end

    puts "\n" + "=" * 60
    puts "📊 PROCESSING SUMMARY"
    puts "✅ Successfully processed: #{processed_count} PDFs"
    puts "❌ Errors: #{error_count} PDFs"
    puts "=" * 60
  end

  def test_ai_connections
    puts "🤖 TESTING AI CONNECTIONS"
    puts "=" * 60

    # Test basic AI connection
    puts "1. Testing OpenAI API connection..."
    begin
      dummy_chapter = Chapter.first || Chapter.new(name: "Test Chapter")
      response = @openai_service.generate_answer("What is mathematics?", dummy_chapter)
      puts "   ✅ AI connection working"
      puts "   📝 Sample response: #{response[0..100]}..."
    rescue => e
      puts "   ❌ AI connection failed: #{e.message}"
    end

    # Test PDF processing
    puts "\n2. Testing PDF reading capabilities..."
    test_pdf = Dir.glob(File.join(@pdf_directory, '**/*.pdf')).first
    if test_pdf
      begin
        pdf = PDF::Reader.new(test_pdf)
        puts "   ✅ PDF reading working (#{pdf.page_count} pages)"
      rescue => e
        puts "   ❌ PDF reading failed: #{e.message}"
      end
    else
      puts "   ⚠️  No PDFs found to test"
    end

    # Test vector embeddings
    puts "\n3. Testing vector embeddings..."
    vector_count = VectorChunk.count
    puts "   📊 Total vector chunks: #{vector_count}"
    if vector_count > 0
      puts "   ✅ Vector embeddings available"
    else
      puts "   ⚠️  No vector embeddings found"
    end

    # Test RAG system
    puts "\n4. Testing RAG system..."
    begin
      test_question = "What are real numbers?"
      test_chapter = Chapter.find_by(name: "Real Numbers")

      if test_chapter
        rag_service = RagService.new(test_chapter)
        response = rag_service.answer_question(test_question)
        puts "   ✅ RAG system working"
        puts "   📝 Sample response: #{response[0..100]}..."
      else
        puts "   ⚠️  No test chapter found for RAG"
      end
    rescue => e
      puts "   ❌ RAG system failed: #{e.message}"
    end
  end

  def rename_all_pdfs_intelligently
    puts "📝 INTELLIGENT PDF RENAMING"
    puts "=" * 60

    renamed_count = 0
    error_count = 0

    Dir.glob(File.join(@pdf_directory, '**/*.pdf')).each do |pdf_path|
      puts "📄 Processing: #{File.basename(pdf_path)}"

      begin
        # Extract chapter information
        chapter_info = extract_chapter_info(pdf_path)

        if chapter_info[:chapter_name].present?
          # Rename file
          new_filename = "#{chapter_info[:chapter_name].downcase.gsub(' ', '_')}.pdf"
          directory = File.dirname(pdf_path)
          new_path = File.join(directory, new_filename)

          unless File.exist?(new_path)
            File.rename(pdf_path, new_path)
            puts "  ✅ Renamed: #{File.basename(pdf_path)} → #{new_filename}"
            renamed_count += 1
          else
            puts "  ⚠️  File already exists: #{new_filename}"
          end
        else
          puts "  ❌ Could not extract chapter name"
          error_count += 1
        end
      rescue => e
        puts "  ❌ Error: #{e.message}"
        error_count += 1
      end
    end

    puts "\n" + "=" * 60
    puts "📊 RENAMING SUMMARY"
    puts "✅ Successfully renamed: #{renamed_count} PDFs"
    puts "❌ Errors: #{error_count} PDFs"
    puts "=" * 60
  end

  private

  def process_single_pdf_with_subject(pdf_path, grade, subject)
    # Extract chapter information from PDF
    chapter_info = extract_chapter_info(pdf_path)

    if chapter_info[:chapter_name].present?
      # Find or create chapter
      chapter = find_or_create_chapter(chapter_info[:chapter_name], subject, chapter_info[:description])

      # Create PDF material
      create_pdf_material(pdf_path, chapter, chapter_info)

      return chapter
    else
      return nil
    end
  end

  def extract_chapter_info(pdf_path)
    begin
      # Read PDF content
      pdf = PDF::Reader.new(pdf_path)
      text_content = extract_text_from_pdf(pdf)

      # Extract chapter information using AI
      chapter_info = extract_chapter_with_ai(text_content)

      # Fallback to filename if AI extraction fails
      if chapter_info[:chapter_name].blank?
        chapter_info = extract_from_filename(File.basename(pdf_path, '.pdf'))
      end

      chapter_info
    rescue => e
      puts "    ❌ Error reading PDF: #{e.message}"
      { chapter_name: nil, description: nil }
    end
  end

  def extract_text_from_pdf(pdf)
    text = ""
    pdf.pages.each do |page|
      text += page.text + "\n"
    end
    text
  end

  def extract_chapter_with_ai(text_content)
    prompt = <<~PROMPT
      Analyze this textbook content and extract chapter information.

      Content:
      #{text_content[0..2000]}

      Please respond with ONLY a JSON object in this exact format:
      {
        "chapter_name": "Real Numbers",
        "description": "This chapter covers real numbers including rational and irrational numbers."
      }

      Do not include any other text, just the JSON object.
    PROMPT

    begin
      dummy_chapter = Chapter.first || Chapter.new(name: "Test Chapter")
      response = @openai_service.generate_answer(prompt, dummy_chapter)

      json_match = response.match(/\{.*\}/m)
      if json_match
        parsed_response = JSON.parse(json_match[0])

        {
          chapter_name: parsed_response['chapter_name'],
          description: parsed_response['description']
        }
      else
        { chapter_name: nil, description: nil }
      end
    rescue => e
      { chapter_name: nil, description: nil }
    end
  end

  def extract_from_filename(filename)
    # Extract chapter name from various filename patterns
    if filename.match(/jemh(\d+)/)
      chapter_num = filename.match(/jemh(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/keph(\d+)/)
      chapter_num = filename.match(/keph(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    else
      chapter_name = filename
        .gsub(/^chapter_\d+_/, '')
        .gsub(/^unit_\d+_/, '')
        .gsub(/_/, ' ')
        .split(' ')
        .map(&:capitalize)
        .join(' ')
    end

    {
      chapter_name: chapter_name,
      description: "Chapter covering #{chapter_name.downcase} concepts."
    }
  end

  def find_or_create_grade(grade_name)
    display_name = grade_name.gsub('class_', 'Grade ').upcase

    Grade.find_or_create_by!(name: display_name) do |grade|
      grade.description = "#{display_name} curriculum"
    end
  end

  def find_or_create_subject(subject_name, grade)
    display_name = subject_name.capitalize

    Subject.find_or_create_by!(name: display_name, grade: grade) do |subject|
      subject.description = "#{display_name} subject for #{grade.name}"
    end
  end

  def find_or_create_chapter(chapter_name, subject, description)
    Chapter.find_or_create_by!(name: chapter_name, subject: subject) do |chapter|
      chapter.description = description || "Chapter covering #{chapter_name.downcase} concepts."
    end
  end

  def create_pdf_material(pdf_path, chapter, chapter_info)
    pdf_material = chapter.pdf_materials.build(
      title: "#{chapter_info[:chapter_name]} Textbook",
      user: User.find_by(email: 'admin@aitutor.com') || User.first
    )

    pdf_material.pdf_file.attach(
      io: File.open(pdf_path),
      filename: "#{chapter_info[:chapter_name].downcase.gsub(' ', '_')}.pdf",
      content_type: 'application/pdf'
    )

    pdf_material.save!

    # Process PDF for vector embeddings
    PdfProcessorJob.perform_later(pdf_material.id)
  end
end
