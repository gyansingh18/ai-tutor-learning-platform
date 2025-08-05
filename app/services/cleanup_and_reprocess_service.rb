class CleanupAndReprocessService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || Rails.root.join('app', 'assets', 'pdfs')
  end

  def cleanup_and_reprocess
    puts "🧹 CLEANUP AND REPROCESS"
    puts "=" * 60

    # 1. Clean up existing data
    cleanup_existing_data

    # 2. Create proper grade-subject relationships
    create_proper_grade_subject_relationships

    # 3. Process PDFs with better filtering
    process_pdfs_with_better_filtering

    # 4. Generate final report
    generate_final_report
  end

  def cleanup_existing_data
    puts "\n🧹 CLEANING UP EXISTING DATA"
    puts "-" * 40

    # Remove duplicate grades
    Grade.where(name: ['GRADE 10']).destroy_all
    puts "  ✅ Removed duplicate grades"

    # Remove chapters that don't have proper subjects
    Chapter.joins(:subject).where(subjects: { grade_id: nil }).destroy_all
    puts "  ✅ Removed orphaned chapters"

    # Remove subjects that don't have proper grades
    Subject.where(grade_id: nil).destroy_all
    puts "  ✅ Removed orphaned subjects"
  end

  def create_proper_grade_subject_relationships
    puts "\n📚 CREATING PROPER GRADE-SUBJECT RELATIONSHIPS"
    puts "-" * 40

    # Create all grades
    (6..12).each do |grade_num|
      grade = Grade.find_or_create_by!(name: "Grade #{grade_num}") do |g|
        g.description = "Grade #{grade_num} curriculum"
      end
      puts "  ✅ #{grade.name}"
    end

    # Define which subjects are available for each grade
    grade_subject_mapping = {
      6 => ['Mathematics', 'Science', 'English', 'Social Studies'],
      7 => ['Mathematics', 'Science', 'English', 'Social Studies'],
      8 => ['Mathematics', 'Science', 'English', 'Social Studies'],
      9 => ['Mathematics', 'Science', 'English', 'Social Studies'],
      10 => ['Mathematics', 'Science', 'English', 'Social Studies'],
      11 => ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Accountancy', 'Business Studies', 'Computer Science', 'Economics', 'Geography', 'History', 'Informatics Practices', 'Political Science', 'Psychology', 'Sociology'],
      12 => ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Accountancy', 'Business Studies', 'Computer Science', 'Economics', 'Geography', 'History', 'Informatics Practices', 'Political Science', 'Psychology', 'Sociology']
    }

    Grade.all.each do |grade|
      grade_num = grade.name.match(/Grade (\d+)/)&.[](1)&.to_i
      subjects = grade_subject_mapping[grade_num] || []

      subjects.each do |subject_name|
        subject = Subject.find_or_create_by!(name: subject_name, grade: grade) do |s|
          s.description = "#{subject_name} for #{grade.name}"
        end
        puts "  ✅ #{subject.name} (#{grade.name})"
      end
    end
  end

  def process_pdfs_with_better_filtering
    puts "\n📄 PROCESSING PDFS WITH BETTER FILTERING"
    puts "-" * 40

    chapter_count = 0
    skipped_count = 0

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
          else
            puts "  ⚠️  Skipped: #{File.basename(pdf_path)} (no chapter name)"
            skipped_count += 1
          end
        else
          puts "  ⚠️  Skipped: #{File.basename(pdf_path)} (no grade/subject match)"
          skipped_count += 1
        end
      rescue => e
        puts "  ❌ Error processing #{File.basename(pdf_path)}: #{e.message}"
        skipped_count += 1
      end
    end

    puts "\n📊 PROCESSING SUMMARY"
    puts "  ✅ Successfully processed: #{chapter_count} chapters"
    puts "  ⚠️  Skipped: #{skipped_count} files"
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
      chapter_name = nil
    end

    {
      chapter_name: chapter_name,
      description: chapter_name ? "Chapter covering #{chapter_name.downcase} concepts." : nil
    }
  end

  def find_grade_from_path(pdf_path)
    path_parts = pdf_path.split('/')
    grade_part = path_parts.find { |part| part.start_with?('class_') }

    if grade_part
      grade_num = grade_part.gsub('class_', '')
      grade_name = "Grade #{grade_num}"
      Grade.find_by(name: grade_name)
    else
      nil
    end
  end

  def find_subject_from_path(pdf_path, grade)
    return nil unless grade

    path_parts = pdf_path.split('/')

    # Map folder names to subject names
    subject_mapping = {
      'mathematics' => 'Mathematics',
      'science' => 'Science',
      'english' => 'English',
      'social_science' => 'Social Studies',
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

    subject_part = path_parts.find { |part| subject_mapping.keys.include?(part) }

    if subject_part
      subject_name = subject_mapping[subject_part]
      Subject.find_by(name: subject_name, grade: grade)
    else
      nil
    end
  end

  def generate_final_report
    puts "\n📊 FINAL SYSTEM REPORT"
    puts "=" * 60

    puts "\n📚 GRADES:"
    Grade.all.each { |g| puts "  - #{g.name}: #{g.subjects.count} subjects" }

    puts "\n📖 SUBJECTS BY GRADE:"
    Grade.all.each do |grade|
      puts "  #{grade.name}:"
      grade.subjects.each { |s| puts "    - #{s.name}: #{s.chapters.count} chapters" }
    end

    puts "\n📈 STATISTICS:"
    puts "  - Total Grades: #{Grade.count}"
    puts "  - Total Subjects: #{Subject.count}"
    puts "  - Total Chapters: #{Chapter.count}"
    puts "  - Total PDF Files: #{Dir.glob(File.join(@pdf_directory, '**/*.pdf')).count}"
  end
end
