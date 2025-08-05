class IntelligentRenamingService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || Rails.root.join('app', 'assets', 'pdfs')
    @openai_service = OpenaiService.new
  end

  def rename_all_entities
    puts "🔄 INTELLIGENT RENAMING OF ALL ENTITIES"
    puts "=" * 60

    # 1. Rename Grades
    rename_grades

    # 2. Rename Subjects
    rename_subjects

    # 3. Rename Chapters
    rename_chapters

    # 4. Rename PDF files
    rename_pdf_files

    puts "\n✅ All entities renamed successfully!"
  end

  def rename_grades
    puts "\n📚 RENAMING GRADES"
    puts "-" * 40

    grade_mapping = {
      'class_6' => 'Grade 6',
      'class_7' => 'Grade 7',
      'class_8' => 'Grade 8',
      'class_9' => 'Grade 9',
      'class_10' => 'Grade 10',
      'class_11' => 'Grade 11',
      'class_12' => 'Grade 12'
    }

    grade_mapping.each do |folder_name, display_name|
      grade = Grade.find_by(name: display_name.upcase)
      if grade
        old_name = grade.name
        grade.update!(name: display_name, description: "#{display_name} curriculum")
        puts "  ✅ #{old_name} → #{display_name}"
      else
        Grade.create!(name: display_name, description: "#{display_name} curriculum")
        puts "  ➕ Created: #{display_name}"
      end
    end
  end

  def rename_subjects
    puts "\n📖 RENAMING SUBJECTS"
    puts "-" * 40

    subject_mapping = {
      'mathematics' => 'Mathematics',
      'maths_class_10 copy' => 'Mathematics',
      'science' => 'Science',
      'science_class_10' => 'Science',
      'english' => 'English',
      'social_science' => 'Social Studies',
      'social_science_class_10' => 'Social Studies',
      'physics' => 'Physics',
      'chemistry' => 'Chemistry',
      'biology' => 'Biology',
      'accountancy' => 'Accountancy',
      'business_studies' => 'Business Studies',
      'computer_science' => 'Computer Science',
      'economics' => 'Economics',
      'geography' => 'Geography',
      'history' => 'History',
      'informatics_practices' => 'Informatics Practices',
      'political_science' => 'Political Science',
      'psychology' => 'Psychology',
      'sociology' => 'Sociology'
    }

    subject_mapping.each do |folder_name, display_name|
      # Find subjects by folder name pattern
      subjects = Subject.joins(:grade).where("LOWER(subjects.name) LIKE ?", "%#{folder_name.gsub('_', '%')}%")

      subjects.each do |subject|
        old_name = subject.name
        subject.update!(name: display_name, description: "#{display_name} subject for #{subject.grade.name}")
        puts "  ✅ #{old_name} → #{display_name} (#{subject.grade.name})"
      end
    end
  end

  def rename_chapters
    puts "\n📄 RENAMING CHAPTERS"
    puts "-" * 40

    # Process all PDFs to extract proper chapter names
    Dir.glob(File.join(@pdf_directory, '**/*.pdf')).each do |pdf_path|
      begin
        chapter_info = extract_chapter_info_from_pdf(pdf_path)

        if chapter_info[:chapter_name].present?
          # Find or create chapter based on PDF path
          grade = find_grade_from_path(pdf_path)
          subject = find_subject_from_path(pdf_path, grade)

          if grade && subject
            # Find existing chapter or create new one
            chapter = Chapter.find_or_create_by!(name: chapter_info[:chapter_name], subject: subject) do |c|
              c.description = chapter_info[:description]
            end

            puts "  ✅ Chapter: #{chapter.name} (#{subject.name} - #{grade.name})"
          end
        end
      rescue => e
        puts "  ❌ Error processing #{File.basename(pdf_path)}: #{e.message}"
      end
    end
  end

  def rename_pdf_files
    puts "\n📝 RENAMING PDF FILES"
    puts "-" * 40

    renamed_count = 0
    error_count = 0

    Dir.glob(File.join(@pdf_directory, '**/*.pdf')).each do |pdf_path|
      begin
        chapter_info = extract_chapter_info_from_pdf(pdf_path)

        if chapter_info[:chapter_name].present?
          # Create new filename
          new_filename = create_intelligent_filename(pdf_path, chapter_info[:chapter_name])
          directory = File.dirname(pdf_path)
          new_path = File.join(directory, new_filename)

          unless File.exist?(new_path)
            File.rename(pdf_path, new_path)
            puts "  ✅ #{File.basename(pdf_path)} → #{new_filename}"
            renamed_count += 1
          else
            puts "  ⚠️  File already exists: #{new_filename}"
          end
        else
          puts "  ❌ Could not extract chapter name from: #{File.basename(pdf_path)}"
          error_count += 1
        end
      rescue => e
        puts "  ❌ Error renaming #{File.basename(pdf_path)}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n📊 RENAMING SUMMARY"
    puts "✅ Successfully renamed: #{renamed_count} files"
    puts "❌ Errors: #{error_count} files"
  end

  def create_intelligent_filename(pdf_path, chapter_name)
    # Extract grade and subject from path
    path_parts = pdf_path.split('/')
    grade_part = path_parts.find { |part| part.start_with?('class_') }
    subject_part = path_parts.find { |part| ['mathematics', 'science', 'english', 'physics', 'chemistry', 'biology'].include?(part) }

    # Create structured filename
    grade_suffix = grade_part&.gsub('class_', 'grade_') || 'unknown_grade'
    subject_suffix = subject_part&.gsub('_', '') || 'unknown_subject'

    # Clean chapter name for filename
    clean_chapter_name = chapter_name
      .downcase
      .gsub(/[^a-z0-9\s]/, '')
      .gsub(/\s+/, '_')
      .strip

    "#{grade_suffix}_#{subject_suffix}_#{clean_chapter_name}.pdf"
  end

  def extract_chapter_info_from_pdf(pdf_path)
    begin
      # Read PDF content
      pdf = PDF::Reader.new(pdf_path)
      text_content = extract_text_from_pdf(pdf)

      # Extract chapter information using AI
      chapter_info = extract_chapter_with_ai(text_content)

      # Fallback to filename if AI extraction fails
      if chapter_info[:chapter_name].blank?
        chapter_info = extract_from_filename_pattern(File.basename(pdf_path, '.pdf'))
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

  def extract_from_filename_pattern(filename)
    # Extract chapter name from various filename patterns
    if filename.match(/jemh(\d+)/)
      chapter_num = filename.match(/jemh(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/keph(\d+)/)
      chapter_num = filename.match(/keph(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kemh(\d+)/)
      chapter_num = filename.match(/kemh(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lemh(\d+)/)
      chapter_num = filename.match(/lemh(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/fegp(\d+)/)
      chapter_num = filename.match(/fegp(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/gegp(\d+)/)
      chapter_num = filename.match(/gegp(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/hegp(\d+)/)
      chapter_num = filename.match(/hegp(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/iemh(\d+)/)
      chapter_num = filename.match(/iemh(\d+)/)[1]
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

  def find_grade_from_path(pdf_path)
    path_parts = pdf_path.split('/')
    grade_part = path_parts.find { |part| part.start_with?('class_') }

    if grade_part
      grade_name = grade_part.gsub('class_', 'Grade ').upcase
      Grade.find_by(name: grade_name)
    else
      nil
    end
  end

  def find_subject_from_path(pdf_path, grade)
    return nil unless grade

    path_parts = pdf_path.split('/')
    subject_part = path_parts.find { |part| ['mathematics', 'science', 'english', 'physics', 'chemistry', 'biology'].include?(part) }

    if subject_part
      subject_name = subject_part.capitalize
      Subject.find_by(name: subject_name, grade: grade)
    else
      nil
    end
  end

  def generate_renaming_report
    puts "\n📊 RENAMING REPORT"
    puts "=" * 60

    puts "\n📚 GRADES:"
    Grade.all.each { |g| puts "  - #{g.name}: #{g.subjects.count} subjects" }

    puts "\n📖 SUBJECTS:"
    Subject.includes(:grade).all.each { |s| puts "  - #{s.name} (#{s.grade.name}): #{s.chapters.count} chapters" }

    puts "\n📄 CHAPTERS:"
    Chapter.includes(:subject).all.each { |c| puts "  - #{c.name} (#{c.subject.name} - #{c.subject.grade.name})" }

    puts "\n📁 PDF FILES:"
    Dir.glob(File.join(@pdf_directory, '**/*.pdf')).each do |pdf_path|
      puts "  - #{File.basename(pdf_path)} (#{File.size(pdf_path) / 1024} KB)"
    end
  end
end
