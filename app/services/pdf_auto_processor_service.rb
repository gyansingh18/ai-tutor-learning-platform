class PdfAutoProcessorService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || Rails.root.join('app', 'assets', 'pdfs')
    @openai_service = OpenaiService.new
  end

  def process_all_pdfs
    puts "🔍 Scanning for PDFs in: #{@pdf_directory}"

    # Create directory structure if it doesn't exist
    create_directory_structure

    # Process each grade folder
    Dir.glob(File.join(@pdf_directory, '*')).each do |grade_path|
      next unless File.directory?(grade_path)

      grade_name = File.basename(grade_path)
      puts "\n📚 Processing Grade: #{grade_name}"

      process_grade_folder(grade_path, grade_name)
    end

    puts "\n✅ PDF processing completed!"
  end

  def process_maths_folder(folder_path)
    puts "📖 Processing Maths Folder: #{folder_path}"

    # Find or create grade and subject
    grade = find_or_create_grade("Grade 10")
    subject = find_or_create_subject("Mathematics", grade)

    # Process each PDF in the maths folder
    Dir.glob(File.join(folder_path, '*.pdf')).each do |pdf_path|
      puts "  📄 Processing PDF: #{File.basename(pdf_path)}"

      process_single_pdf_with_subject(pdf_path, grade, subject)
    end
  end

  def process_single_pdf_with_subject(pdf_path, grade, subject)
    puts "📄 Processing single PDF: #{File.basename(pdf_path)}"

    # Extract chapter information from PDF
    chapter_info = extract_chapter_info(pdf_path)

    if chapter_info[:chapter_name].present?
      # Find or create chapter
      chapter = find_or_create_chapter(chapter_info[:chapter_name], subject, chapter_info[:description])

      # Create PDF material
      create_pdf_material(pdf_path, chapter, chapter_info)

      # Rename PDF file to match chapter name
      rename_pdf_file(pdf_path, chapter_info[:chapter_name])

      puts "✅ Created chapter: #{chapter_info[:chapter_name]}"
      return chapter
    else
      puts "⚠️  Could not extract chapter name from: #{File.basename(pdf_path)}"
      return nil
    end
  end

  def process_single_pdf(pdf_path)
    puts "📄 Processing single PDF: #{File.basename(pdf_path)}"

    # Extract chapter information from PDF
    chapter_info = extract_chapter_info(pdf_path)

    if chapter_info[:chapter_name].present?
      # Find or create grade and subject
      grade = find_or_create_grade_from_path(pdf_path)
      subject = find_or_create_subject_from_path(pdf_path, grade)

      # Find or create chapter
      chapter = find_or_create_chapter(chapter_info[:chapter_name], subject, chapter_info[:description])

      # Create PDF material
      create_pdf_material(pdf_path, chapter, chapter_info)

      # Rename PDF file to match chapter name
      rename_pdf_file(pdf_path, chapter_info[:chapter_name])

      puts "✅ Created chapter: #{chapter_info[:chapter_name]}"
      return chapter
    else
      puts "⚠️  Could not extract chapter name from: #{File.basename(pdf_path)}"
      return nil
    end
  end

  private

  def create_directory_structure
    # Create base directory structure
    base_structure = [
      'class_6/mathematics',
      'class_6/science',
      'class_7/mathematics',
      'class_7/science',
      'class_8/mathematics',
      'class_8/science',
      'class_9/mathematics',
      'class_9/science',
      'class_10/mathematics',
      'class_10/science'
    ]

    base_structure.each do |path|
      full_path = File.join(@pdf_directory, path)
      FileUtils.mkdir_p(full_path) unless Dir.exist?(full_path)
    end

    puts "📁 Created directory structure"
  end

  def process_grade_folder(grade_path, grade_name)
    # Find or create grade
    grade = find_or_create_grade(grade_name)

    # Process each subject folder
    Dir.glob(File.join(grade_path, '*')).each do |subject_path|
      next unless File.directory?(subject_path)

      subject_name = File.basename(subject_path)
      puts "  📖 Processing Subject: #{subject_name}"

      # Check if it's a maths folder
      if subject_name.include?('maths')
        process_maths_folder(subject_path)
      else
        process_subject_folder(subject_path, subject_name, grade)
      end
    end
  end

  def process_subject_folder(subject_path, subject_name, grade)
    # Find or create subject
    subject = find_or_create_subject(subject_name, grade)

    # Process each PDF in the subject folder
    Dir.glob(File.join(subject_path, '*.pdf')).each do |pdf_path|
      puts "    📄 Processing PDF: #{File.basename(pdf_path)}"

      process_single_pdf(pdf_path)
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
    # Use AI to extract chapter information
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
      # Use a dummy chapter for the method call
      dummy_chapter = Chapter.first || Chapter.new(name: "Test Chapter")
      response = @openai_service.generate_answer(prompt, dummy_chapter)

      # Clean the response to extract JSON
      json_match = response.match(/\{.*\}/m)
      if json_match
        parsed_response = JSON.parse(json_match[0])

        {
          chapter_name: parsed_response['chapter_name'],
          description: parsed_response['description']
        }
      else
        puts "    ⚠️  Could not extract JSON from AI response"
        { chapter_name: nil, description: nil }
      end
    rescue => e
      puts "    ⚠️  AI extraction failed: #{e.message}"
      { chapter_name: nil, description: nil }
    end
  end

  def extract_from_filename(filename)
    # Extract chapter name from filename
    # Example: "jemh101.pdf" -> "Chapter 1"
    # Example: "chapter_1_numbers.pdf" -> "Numbers"

    # Try to extract chapter number from filename
    if filename.match(/jemh(\d+)/)
      chapter_num = filename.match(/jemh(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    else
      chapter_name = filename
        .gsub(/^chapter_\d+_/, '') # Remove "chapter_1_" prefix
        .gsub(/^unit_\d+_/, '')    # Remove "unit_1_" prefix
        .gsub(/_/, ' ')            # Replace underscores with spaces
        .split(' ')
        .map(&:capitalize)
        .join(' ')
    end

    {
      chapter_name: chapter_name,
      description: "Chapter covering #{chapter_name.downcase} concepts."
    }
  end

  def find_or_create_grade_from_path(pdf_path)
    # Extract grade from path
    path_parts = pdf_path.split('/')
    grade_part = path_parts.find { |part| part.start_with?('class_') }

    if grade_part
      grade_name = grade_part.gsub('class_', 'Grade ').upcase
      find_or_create_grade(grade_name)
    else
      # Default to Grade 10 if not found
      find_or_create_grade("Grade 10")
    end
  end

  def find_or_create_subject_from_path(pdf_path, grade)
    # Extract subject from path
    path_parts = pdf_path.split('/')
    subject_part = path_parts.find { |part| ['mathematics', 'science', 'english'].include?(part) }

    if subject_part
      subject_name = subject_part.capitalize
      find_or_create_subject(subject_name, grade)
    else
      # Default to Mathematics if not found
      find_or_create_subject("Mathematics", grade)
    end
  end

  def find_or_create_grade(grade_name)
    # Convert "class_6" to "Grade 6"
    display_name = grade_name.gsub('class_', 'Grade ').upcase

    Grade.find_or_create_by!(name: display_name) do |grade|
      grade.description = "#{display_name} curriculum"
    end
  end

  def find_or_create_subject(subject_name, grade)
    # Convert "mathematics" to "Mathematics"
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
    # Create PDF material record
    pdf_material = chapter.pdf_materials.build(
      title: "#{chapter_info[:chapter_name]} Textbook",
      user: User.find_by(email: 'admin@aitutor.com') || User.first
    )

    # Attach the PDF file
    pdf_material.pdf_file.attach(
      io: File.open(pdf_path),
      filename: "#{chapter_info[:chapter_name].downcase.gsub(' ', '_')}.pdf",
      content_type: 'application/pdf'
    )

    pdf_material.save!

    # Process PDF for vector embeddings
    PdfProcessorJob.perform_later(pdf_material.id)

    puts "    ✅ Created PDF material: #{pdf_material.title}"
  end

  def rename_pdf_file(pdf_path, chapter_name)
    # Rename PDF file to match chapter name
    directory = File.dirname(pdf_path)
    new_filename = "#{chapter_name.downcase.gsub(' ', '_')}.pdf"
    new_path = File.join(directory, new_filename)

    unless File.exist?(new_path)
      File.rename(pdf_path, new_path)
      puts "    📝 Renamed: #{File.basename(pdf_path)} → #{new_filename}"
    end
  end
end
