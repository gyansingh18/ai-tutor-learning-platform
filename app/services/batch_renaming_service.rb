class BatchRenamingService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || Rails.root.join('app', 'assets', 'pdfs')
    @openai_service = OpenaiService.new
  end

  def rename_in_batches
    puts "🔄 BATCH RENAMING OF ENTITIES"
    puts "=" * 60

    # 1. Clean up duplicate grades
    cleanup_grades

    # 2. Rename subjects in batches
    rename_subjects_batch

    # 3. Create chapters from filename patterns (faster than reading PDFs)
    create_chapters_from_patterns

    # 4. Generate renaming report
    generate_report
  end

  def cleanup_grades
    puts "\n🧹 CLEANING UP GRADES"
    puts "-" * 40

    # Remove duplicate grades
    Grade.where(name: ['6', '7', '8', '9', '10']).destroy_all

    # Ensure proper grade names
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
      grade = Grade.find_or_create_by!(name: display_name) do |g|
        g.description = "#{display_name} curriculum"
      end
      puts "  ✅ #{display_name}"
    end
  end

  def rename_subjects_batch
    puts "\n📖 RENAMING SUBJECTS IN BATCHES"
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

  def create_chapters_from_patterns
    puts "\n📄 CREATING CHAPTERS FROM FILENAME PATTERNS"
    puts "-" * 40

    chapter_count = 0

    Dir.glob(File.join(@pdf_directory, '**/*.pdf')).each do |pdf_path|
      begin
        # Extract grade and subject from path
        grade = find_grade_from_path(pdf_path)
        subject = find_subject_from_path(pdf_path, grade)

        if grade && subject
          # Extract chapter name from filename
          chapter_info = extract_chapter_from_filename(File.basename(pdf_path, '.pdf'))

          if chapter_info[:chapter_name].present?
            # Create chapter
            chapter = Chapter.find_or_create_by!(name: chapter_info[:chapter_name], subject: subject) do |c|
              c.description = chapter_info[:description]
            end

            puts "  ✅ #{chapter.name} (#{subject.name} - #{grade.name})"
            chapter_count += 1
          end
        end
      rescue => e
        puts "  ❌ Error processing #{File.basename(pdf_path)}: #{e.message}"
      end
    end

    puts "  📊 Created/Updated #{chapter_count} chapters"
  end

  def extract_chapter_from_filename(filename)
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
    elsif filename.match(/jeff(\d+)/)
      chapter_num = filename.match(/jeff(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/jesc(\d+)/)
      chapter_num = filename.match(/jesc(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/jess(\d+)/)
      chapter_num = filename.match(/jess(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/keac(\d+)/)
      chapter_num = filename.match(/keac(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kebo(\d+)/)
      chapter_num = filename.match(/kebo(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kebs(\d+)/)
      chapter_num = filename.match(/kebs(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kech(\d+)/)
      chapter_num = filename.match(/kech(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kecs(\d+)/)
      chapter_num = filename.match(/kecs(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/keec(\d+)/)
      chapter_num = filename.match(/keec(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kegy(\d+)/)
      chapter_num = filename.match(/kegy(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kehs(\d+)/)
      chapter_num = filename.match(/kehs(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/keip(\d+)/)
      chapter_num = filename.match(/keip(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/keps(\d+)/)
      chapter_num = filename.match(/keps(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kepy(\d+)/)
      chapter_num = filename.match(/kepy(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/kesy(\d+)/)
      chapter_num = filename.match(/kesy(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/leac(\d+)/)
      chapter_num = filename.match(/leac(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lebo(\d+)/)
      chapter_num = filename.match(/lebo(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lebs(\d+)/)
      chapter_num = filename.match(/lebs(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lech(\d+)/)
      chapter_num = filename.match(/lech(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lecs(\d+)/)
      chapter_num = filename.match(/lecs(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/leec(\d+)/)
      chapter_num = filename.match(/leec(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/legy(\d+)/)
      chapter_num = filename.match(/legy(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lehs(\d+)/)
      chapter_num = filename.match(/lehs(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/leip(\d+)/)
      chapter_num = filename.match(/leip(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/leph(\d+)/)
      chapter_num = filename.match(/leph(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/leps(\d+)/)
      chapter_num = filename.match(/leps(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lepy(\d+)/)
      chapter_num = filename.match(/lepy(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/lesy(\d+)/)
      chapter_num = filename.match(/lesy(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/fepr(\d+)/)
      chapter_num = filename.match(/fepr(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/fegp(\d+)/)
      chapter_num = filename.match(/fegp(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/fecu(\d+)/)
      chapter_num = filename.match(/fecu(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/fees(\d+)/)
      chapter_num = filename.match(/fees(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/gepr(\d+)/)
      chapter_num = filename.match(/gepr(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/gegp(\d+)/)
      chapter_num = filename.match(/gegp(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/gecu(\d+)/)
      chapter_num = filename.match(/gecu(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/gees(\d+)/)
      chapter_num = filename.match(/gees(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/hepr(\d+)/)
      chapter_num = filename.match(/hepr(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/hegp(\d+)/)
      chapter_num = filename.match(/hegp(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/hecu(\d+)/)
      chapter_num = filename.match(/hecu(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/hees(\d+)/)
      chapter_num = filename.match(/hees(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/iebe(\d+)/)
      chapter_num = filename.match(/iebe(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/iemh(\d+)/)
      chapter_num = filename.match(/iemh(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/iesc(\d+)/)
      chapter_num = filename.match(/iesc(\d+)/)[1]
      chapter_name = "Chapter #{chapter_num}"
    elsif filename.match(/iess(\d+)/)
      chapter_num = filename.match(/iess(\d+)/)[1]
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
    subject_part = path_parts.find { |part| ['mathematics', 'science', 'english', 'physics', 'chemistry', 'biology', 'accountancy', 'business_studies', 'computer_science', 'economics', 'geography', 'history', 'informatics_practices', 'political_science', 'psychology', 'sociology', 'social_science'].include?(part) }

    if subject_part
      subject_name = subject_part.capitalize
      Subject.find_by(name: subject_name, grade: grade)
    else
      nil
    end
  end

  def generate_report
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
