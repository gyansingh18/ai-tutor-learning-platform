require 'pdf-reader'

class PdfContentReaderService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || Rails.root.join('app', 'assets', 'pdfs')
    @openai_service = OpenaiService.new
  end

  def read_and_extract_chapter_info(pdf_path)
    begin
      # Read PDF content
      pdf = PDF::Reader.new(pdf_path)
      text_content = extract_text_from_pdf(pdf)

      # Extract chapter information using AI
      chapter_info = extract_chapter_with_ai(text_content, File.basename(pdf_path))

      # If AI extraction fails, try filename pattern
      if chapter_info[:chapter_name].blank?
        chapter_info = extract_from_filename_pattern(File.basename(pdf_path, '.pdf'))
      end

      chapter_info
    rescue => e
      puts "  ❌ Error reading #{File.basename(pdf_path)}: #{e.message}"
      # Fallback to filename pattern
      extract_from_filename_pattern(File.basename(pdf_path, '.pdf'))
    end
  end

  def extract_text_from_pdf(pdf)
    text_content = ""
    pdf.pages.each do |page|
      text_content += page.text + "\n"
    end
    text_content
  end

  def extract_chapter_with_ai(text_content, filename)
    prompt = <<~PROMPT
      Analyze this textbook content and extract chapter information.

      Filename: #{filename}
      Content (first 3000 characters):
      #{text_content[0..3000]}

      Please respond with ONLY a JSON object in this exact format:
      {
        "is_chapter": true/false,
        "chapter_name": "Real Numbers",
        "chapter_number": "1",
        "description": "This chapter covers real numbers including rational and irrational numbers."
      }

      Rules:
      - If this is NOT a chapter (like index, preface, appendix, etc.), set "is_chapter" to false
      - If this IS a chapter, set "is_chapter" to true and provide chapter details
      - Use the actual chapter name and number from the content
      - Do not include any other text, just the JSON object
    PROMPT

    begin
      dummy_chapter = Chapter.first || Chapter.new(name: "Test Chapter")
      response = @openai_service.generate_answer(prompt, dummy_chapter)

      json_match = response.match(/\{.*\}/m)
      if json_match
        parsed_response = JSON.parse(json_match[0])

        if parsed_response['is_chapter']
          {
            chapter_name: parsed_response['chapter_name'],
            chapter_number: parsed_response['chapter_number'],
            description: parsed_response['description'],
            is_chapter: true
          }
        else
          {
            chapter_name: nil,
            chapter_number: nil,
            description: "Non-chapter content",
            is_chapter: false
          }
        end
      else
        {
          chapter_name: nil,
          chapter_number: nil,
          description: "Could not parse AI response",
          is_chapter: false
        }
      end
    rescue => e
      puts "  ⚠️  AI extraction failed for #{filename}: #{e.message}"
      {
        chapter_name: nil,
        chapter_number: nil,
        description: "AI extraction failed",
        is_chapter: false
      }
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
      chapter_number: chapter_name.match(/Chapter (\d+)/)&.[](1) || "1",
      description: "Chapter covering #{chapter_name.downcase} concepts.",
      is_chapter: true
    }
  end

  def process_all_pdfs_with_content_reading
    puts "📖 PROCESSING PDFS WITH CONTENT READING"
    puts "=" * 60

    chapter_count = 0
    non_chapter_count = 0
    error_count = 0

    Dir.glob(File.join(@pdf_directory, '**/*.pdf')).each do |pdf_path|
      begin
        puts "  📄 Processing: #{File.basename(pdf_path)}"

        # Read PDF content and extract chapter info
        chapter_info = read_and_extract_chapter_info(pdf_path)

        if chapter_info[:is_chapter] && chapter_info[:chapter_name].present?
          # Extract grade and subject from path
          grade = find_grade_from_path(pdf_path)
          subject = find_subject_from_path(pdf_path, grade)

          if grade && subject
            # Create chapter with real name and number
            chapter = Chapter.find_or_create_by!(name: chapter_info[:chapter_name], subject: subject) do |c|
              c.description = chapter_info[:description]
            end

            puts "    ✅ Chapter: #{chapter.name} (#{subject.name} - #{grade.name})"
            chapter_count += 1
          else
            puts "    ⚠️  Skipped: No grade/subject match"
          end
        else
          puts "    ⚠️  Skipped: Not a chapter content"
          non_chapter_count += 1
        end
      rescue => e
        puts "    ❌ Error: #{e.message}"
        error_count += 1
      end
    end

    puts "\n📊 CONTENT READING SUMMARY"
    puts "  ✅ Chapters created: #{chapter_count}"
    puts "  ⚠️  Non-chapter content: #{non_chapter_count}"
    puts "  ❌ Errors: #{error_count}"
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
end
