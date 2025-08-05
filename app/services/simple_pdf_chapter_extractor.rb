require 'pdf-reader'

class SimplePdfChapterExtractor
  def initialize(pdf_directory = nil)
    @pdf_directory = pdf_directory || Rails.root.join('app', 'assets', 'pdfs')
  end

  def extract_chapter_names_from_text
    puts "📖 EXTRACTING CHAPTER NAMES FROM PDF TEXT"
    puts "=" * 60

    processed_count = 0
    error_count = 0

    Chapter.all.each do |chapter|
      begin
        # Find PDF file for this chapter
        pdf_file = find_pdf_for_chapter(chapter)

        if pdf_file
          puts "  📄 Processing: #{chapter.name} (#{chapter.subject.name} - #{chapter.subject.grade.name})"

          # Read PDF content and extract chapter name from text
          real_chapter_name = extract_chapter_from_text(pdf_file)

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

  def find_pdf_for_chapter(chapter)
    # Look for PDF files that match the chapter's subject and grade
    subject_folder = map_subject_to_folder(chapter.subject.name)
    grade_folder = "class_#{chapter.subject.grade.name.match(/Grade (\d+)/)[1]}"

    pdf_pattern = File.join(@pdf_directory, grade_folder, subject_folder, '**/*.pdf')

    Dir.glob(pdf_pattern).find do |pdf_path|
      # Try to match by chapter number in filename
      chapter_num = extract_chapter_number_from_filename(File.basename(pdf_path))
      chapter.name.include?(chapter_num.to_s) if chapter_num
    end
  end

  def extract_chapter_from_text(pdf_path)
    begin
      # Read PDF content
      pdf = PDF::Reader.new(pdf_path)
      text_content = extract_text_from_pdf(pdf)

      # Look for chapter patterns in the text
      chapter_name = find_chapter_in_text(text_content, pdf_path)

      chapter_name
    rescue => e
      puts "    ❌ Error reading PDF: #{e.message}"
      nil
    end
  end

  def extract_text_from_pdf(pdf)
    text_content = ""
    # Read first few pages to get chapter information
    pdf.pages.first(5).each do |page|
      text_content += page.text + "\n"
    end
    text_content
  end

  def find_chapter_in_text(text_content, pdf_path = nil)
    # First, try to find chapter titles at the beginning of the content
    lines = text_content.split("\n")

    # Look for chapter patterns in the first 20 lines
    lines.first(20).each do |line|
      # Look for chapter patterns
      chapter_patterns = [
        /^Chapter\s+(\d+)[:\s]*([^\\n]+)/i,
        /^CHAPTER\s+(\d+)[:\s]*([^\\n]+)/i,
        /^(\d+)\.\s*([^\\n]+)/i,
        /^Chapter\s+([^\\n]+)/i,
        /^CHAPTER\s+([^\\n]+)/i
      ]

      chapter_patterns.each do |pattern|
        match = line.match(pattern)
        if match
          if match[1] && match[2]
            # Pattern with number and title
            title = clean_chapter_title(match[2].strip)
            return "Chapter #{match[1]}: #{title}"
          elsif match[1]
            # Pattern with just title
            title = clean_chapter_title(match[1].strip)
            return "Chapter: #{title}"
          end
        end
      end

      # Look for textbook unit patterns
      unit_patterns = [
        /^Unit\s+(\d+)[:\s]*([^\\n]+)/i,
        /^UNIT\s+(\d+)[:\s]*([^\\n]+)/i,
        /^Lesson\s+(\d+)[:\s]*([^\\n]+)/i,
        /^LESSON\s+(\d+)[:\s]*([^\\n]+)/i
      ]

      unit_patterns.each do |pattern|
        match = line.match(pattern)
        if match && match[1] && match[2]
          title = clean_chapter_title(match[2].strip)
          return "Unit #{match[1]}: #{title}"
        end
      end
    end

    # If no chapter found in first lines, look for subject-specific patterns
    subject = get_subject_from_filename(File.basename(pdf_path))
    subject_patterns = get_subject_patterns(subject)

    if subject_patterns
      subject_patterns.each do |pattern|
        if text_content.match(pattern)
          return pattern.source.gsub(/[\/i]/, '').strip
        end
      end
    end

    # Look for exercise patterns that might indicate chapter content
    exercise_patterns = [
      /EXERCISE\s+(\d+\.\d+)/i,
      /Exercise\s+(\d+\.\d+)/i,
      /EXERCISE\s+(\d+)/i,
      /Exercise\s+(\d+)/i
    ]

    exercise_patterns.each do |pattern|
      match = text_content.match(pattern)
      if match
        exercise_num = match[1]
        # Try to find chapter number from exercise number
        if exercise_num.match(/^(\d+)\./)
          chapter_num = $1
          return "Chapter #{chapter_num}: Exercise #{exercise_num}"
        elsif exercise_num.match(/^(\d+)/)
          chapter_num = $1
          return "Chapter #{chapter_num}: Exercise #{exercise_num}"
        end
      end
    end

    nil
  end

  def clean_chapter_title(title)
    # Clean up the chapter title
    cleaned = title
      .gsub(/\s+/, ' ')  # Replace multiple spaces with single space
      .gsub(/[^\w\s\-:()]/, '')  # Remove special characters except letters, numbers, spaces, hyphens, colons, parentheses
      .strip

    # Limit length
    if cleaned.length > 100
      cleaned = cleaned[0..100] + "..."
    end

    cleaned
  end

  def get_subject_from_filename(filename)
    # Extract subject from filename patterns
    if filename.match(/kemh/)
      'Mathematics'
    elsif filename.match(/keph/)
      'Physics'
    elsif filename.match(/kech/)
      'Chemistry'
    elsif filename.match(/kehs/)
      'Biology'
    elsif filename.match(/keac/)
      'Accountancy'
    elsif filename.match(/kebs/)
      'Business Studies'
    else
      'Unknown'
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

  def get_subject_patterns(subject)
    patterns = {
      'Mathematics' => [
        /Real\s+Numbers/i,
        /Polynomials/i,
        /Linear\s+Equations/i,
        /Quadratic\s+Equations/i,
        /Trigonometry/i,
        /Statistics/i,
        /Probability/i,
        /Sets/i,
        /Relations\s+and\s+Functions/i,
        /Complex\s+Numbers/i,
        /Matrices/i,
        /Determinants/i,
        /Limits\s+and\s+Derivatives/i,
        /Integrals/i,
        /Differential\s+Equations/i,
        /Vector\s+Algebra/i,
        /Three\s+Dimensional\s+Geometry/i,
        /Linear\s+Programming/i
      ],
      'Physics' => [
        /Mechanics/i,
        /Thermodynamics/i,
        /Electromagnetism/i,
        /Optics/i,
        /Modern\s+Physics/i,
        /Kinematics/i,
        /Dynamics/i,
        /Work\s+and\s+Energy/i,
        /Gravitation/i,
        /Wave\s+Motion/i,
        /Electric\s+Charges/i,
        /Current\s+Electricity/i,
        /Magnetic\s+Effects/i,
        /Electromagnetic\s+Induction/i,
        /Ray\s+Optics/i,
        /Wave\s+Optics/i,
        /Dual\s+Nature/i,
        /Atoms\s+and\s+Nuclei/i
      ],
      'Chemistry' => [
        /Atomic\s+Structure/i,
        /Chemical\s+Bonding/i,
        /Thermodynamics/i,
        /Organic\s+Chemistry/i,
        /Inorganic\s+Chemistry/i,
        /Solutions/i,
        /Electrochemistry/i,
        /Chemical\s+Kinetics/i,
        /Surface\s+Chemistry/i,
        /Nuclear\s+Chemistry/i,
        /Coordination\s+Compounds/i,
        /Haloalkanes/i,
        /Alcohols/i,
        /Aldehydes/i,
        /Carboxylic\s+Acids/i,
        /Amines/i,
        /Biomolecules/i,
        /Polymers/i
      ],
      'Biology' => [
        /Cell\s+Biology/i,
        /Genetics/i,
        /Evolution/i,
        /Ecology/i,
        /Human\s+Physiology/i,
        /Plant\s+Physiology/i,
        /Microbiology/i,
        /Biotechnology/i,
        /Human\s+Health/i,
        /Reproduction/i,
        /Growth\s+and\s+Development/i,
        /Neural\s+Control/i,
        /Chemical\s+Coordination/i,
        /Locomotion/i,
        /Excretory\s+Products/i,
        /Breathing/i,
        /Body\s+Fluids/i,
        /Digestion/i
      ]
    }

    patterns[subject]
  end

  def test_single_pdf(pdf_path)
    puts "🧪 TESTING PDF: #{File.basename(pdf_path)}"
    puts "-" * 40

    begin
      real_chapter_name = extract_chapter_from_text(pdf_path)

      if real_chapter_name
        puts "  ✅ Extracted: #{real_chapter_name}"
      else
        puts "  ❌ No chapter name found"

        # Show first 500 characters of text for debugging
        pdf = PDF::Reader.new(pdf_path)
        text_content = extract_text_from_pdf(pdf)
        puts "  📄 First 500 chars: #{text_content[0..500]}"
      end
    rescue => e
      puts "  ❌ Error: #{e.message}"
    end
  end
end
