require 'pdf-reader'

class PdfChapterExtractorService
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || "pdfs"  # Changed from local path to S3 prefix
    @openai_service = OpenaiService.new
  end

  def extract_real_chapter_names
    puts "📖 EXTRACTING REAL CHAPTER NAMES FROM PDF CONTENT (S3)"
    puts "=" * 60

    processed_count = 0
    error_count = 0

    Chapter.all.each do |chapter|
      begin
        # Find PDF file for this chapter in S3
        pdf_key = find_pdf_for_chapter_in_s3(chapter)

        if pdf_key
          puts "  📄 Processing: #{chapter.name} (#{chapter.subject.name} - #{chapter.subject.grade.name})"

          # Read PDF content from S3 and extract real chapter name
          real_chapter_name = extract_chapter_name_from_s3_pdf(pdf_key)

          if real_chapter_name.present? && real_chapter_name != chapter.name
            old_name = chapter.name
            chapter.update!(name: real_chapter_name)
            puts "    ✅ Updated: '#{old_name}' → '#{real_chapter_name}'"
            processed_count += 1
          else
            puts "    ⚠️  No change needed or no real name found"
          end
        else
          puts "    ⚠️  No PDF file found for chapter: #{chapter.name}"
        end
      rescue => e
        puts "    ❌ Error processing #{chapter.name}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n📊 EXTRACTION SUMMARY"
    puts "  ✅ Successfully processed: #{processed_count} chapters"
    puts "  ❌ Errors: #{error_count} chapters"
  end

  def find_pdf_for_chapter_in_s3(chapter)
    # Look for PDF files in S3 that match the chapter's subject and grade
    subject_folder = map_subject_to_folder(chapter.subject.name)
    grade_folder = "class_#{chapter.subject.grade.name.match(/Grade (\d+)/)[1]}"

    s3_prefix = "#{@pdf_directory}/#{grade_folder}/#{subject_folder}/"

    # Use S3 service to find PDFs
    pdfs = S3PdfService.list_pdfs_by_prefix(s3_prefix)

    pdfs.find do |pdf_key|
      # Try to match by chapter number in filename
      chapter_num = extract_chapter_number_from_filename(File.basename(pdf_key))
      chapter.name.include?(chapter_num.to_s) if chapter_num
    end
  end

  def extract_chapter_name_from_s3_pdf(pdf_key)
    begin
      # Download PDF content from S3 temporarily
      temp_file = download_pdf_from_s3(pdf_key)

      # Read PDF content
      pdf = PDF::Reader.new(temp_file.path)
      text_content = extract_text_from_pdf(pdf)

      # Use AI to extract real chapter name
      real_chapter_name = extract_chapter_name_with_ai(text_content, File.basename(pdf_key))

      # Clean up temp file
      temp_file.close
      temp_file.unlink

      real_chapter_name
    rescue => e
      puts "    ❌ Error reading PDF from S3: #{e.message}"
      nil
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

  def extract_text_from_pdf(pdf)
    text_content = ""
    # Read first few pages to get chapter information
    pdf.pages.first(5).each do |page|
      text_content += page.text + "\n"
    end
    text_content
  end

  def extract_chapter_name_with_ai(text_content, filename)
    prompt = <<~PROMPT
      Analyze this textbook content and extract the real chapter name and number.

      Filename: #{filename}
      Content (first 2000 characters):
      #{text_content[0..2000]}

      Please respond with ONLY a JSON object in this exact format:
      {
        "chapter_name": "Real Numbers",
        "chapter_number": "1",
        "full_title": "Chapter 1: Real Numbers"
      }

      Rules:
      - Look for chapter titles, headings, or section names in the content
      - Use the actual chapter name from the textbook content
      - Include the chapter number if available
      - If no clear chapter name is found, return null for chapter_name
      - Do not include any other text, just the JSON object
    PROMPT

    begin
      dummy_chapter = Chapter.first || Chapter.new(name: "Test Chapter")
      response = @openai_service.generate_answer(prompt, dummy_chapter)

      json_match = response.match(/\{.*\}/m)
      if json_match
        parsed_response = JSON.parse(json_match[0])

        if parsed_response['chapter_name'].present?
          # Return the full title if available, otherwise just the chapter name
          parsed_response['full_title'] || parsed_response['chapter_name']
        else
          nil
        end
      else
        nil
      end
    rescue => e
      puts "    ⚠️  AI extraction failed: #{e.message}"
      nil
    end
  end

  def extract_chapter_number_from_filename(filename)
    # Extract chapter number from various filename patterns
    patterns = [
      /jemh(\d+)/, /keph(\d+)/, /kemh(\d+)/, /lemh(\d+)/,
      /fegp(\d+)/, /gegp(\d+)/, /hegp(\d+)/, /iemh(\d+)/,
      /jeff(\d+)/, /jesc(\d+)/, /jess(\d+)/, /keac(\d+)/,
      /kebo(\d+)/, /kebs(\d+)/, /kech(\d+)/, /kecs(\d+)/,
      /keec(\d+)/, /kegy(\d+)/, /kehs(\d+)/, /keip(\d+)/,
      /keps(\d+)/, /kepy(\d+)/, /kesy(\d+)/, /leac(\d+)/,
      /lebo(\d+)/, /lebs(\d+)/, /lech(\d+)/, /lecs(\d+)/,
      /leec(\d+)/, /legy(\d+)/, /lehs(\d+)/, /leip(\d+)/,
      /leph(\d+)/, /leps(\d+)/, /lepy(\d+)/, /lesy(\d+)/,
      /fepr(\d+)/, /fecu(\d+)/, /fees(\d+)/, /gepr(\d+)/,
      /gecu(\d+)/, /gees(\d+)/, /hepr(\d+)/, /hecu(\d+)/,
      /hees(\d+)/, /iebe(\d+)/, /iesc(\d+)/, /iess(\d+)/
    ]

    patterns.each do |pattern|
      match = filename.match(pattern)
      return match[1] if match
    end

    nil
  end

  def map_subject_to_folder(subject_name)
    # Map subject names to folder names
    mapping = {
      'Mathematics' => 'mathematics',
      'Science' => 'science',
      'English' => 'english',
      'Social Studies' => 'social_science',
      'Physics' => 'physics',
      'Chemistry' => 'chemistry',
      'Biology' => 'biology',
      'Accountancy' => 'accountancy',
      'Business Studies' => 'business_studies',
      'Computer Science' => 'computer_science',
      'Economics' => 'economics',
      'Geography' => 'geography',
      'History' => 'history',
      'Informatics Practices' => 'informatics_practices',
      'Political Science' => 'political_science',
      'Psychology' => 'psychology',
      'Sociology' => 'sociology'
    }

    mapping[subject_name] || subject_name.downcase.gsub(' ', '_')
  end

  def test_single_pdf(pdf_path)
    puts "🧪 TESTING PDF: #{File.basename(pdf_path)}"
    puts "-" * 40

    begin
      real_chapter_name = extract_chapter_name_from_pdf(pdf_path)

      if real_chapter_name
        puts "  ✅ Extracted: #{real_chapter_name}"
      else
        puts "  ❌ No chapter name found"
      end
    rescue => e
      puts "  ❌ Error: #{e.message}"
    end
  end
end
