class BulkPdfImportService
  def initialize
    @pdf_base_path = Rails.root.join('app', 'assets', 'pdfs')
    @imported_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import_all
    puts "🚀 Starting bulk PDF import..."
    puts "📁 Scanning directory: #{@pdf_base_path}"

    # Get all PDF files
    pdf_files = Dir.glob("#{@pdf_base_path}/**/*.pdf")
    puts "📄 Found #{pdf_files.count} PDF files"

    pdf_files.each do |pdf_path|
      import_single_pdf(pdf_path)
    end

    puts "\n✅ Import completed!"
    puts "📊 Summary:"
    puts "   - Imported: #{@imported_count} PDFs"
    puts "   - Skipped: #{@skipped_count} PDFs"
    puts "   - Errors: #{@errors.count}"

    if @errors.any?
      puts "\n❌ Errors encountered:"
      @errors.each { |error| puts "   - #{error}" }
    end

    { imported: @imported_count, skipped: @skipped_count, errors: @errors }
  end

  private

  def import_single_pdf(pdf_path)
    # Extract information from path
    relative_path = pdf_path.gsub("#{@pdf_base_path}/", '')
    path_parts = relative_path.split('/')

    return skip_pdf(pdf_path, "Invalid path structure") if path_parts.length < 3

    # Parse path: class_X/subject/filename.pdf
    grade_folder = path_parts[0] # e.g., "class_10"
    subject_folder = path_parts[1] # e.g., "mathematics"
    filename = File.basename(pdf_path, '.pdf') # e.g., "keac101"

    # Extract grade number
    grade_number = extract_grade_number(grade_folder)
    return skip_pdf(pdf_path, "Could not extract grade") unless grade_number

    # Find matching grade
    grade = Grade.find_by("name ILIKE ? OR name ILIKE ?", "Grade #{grade_number}", "Class #{grade_number}")
    return skip_pdf(pdf_path, "Grade #{grade_number} not found") unless grade

    # Find matching subject
    subject = find_matching_subject(grade, subject_folder)
    return skip_pdf(pdf_path, "Subject '#{subject_folder}' not found for grade #{grade_number}") unless subject

    # Find or create matching chapter
    chapter = find_or_create_chapter(subject, filename, pdf_path)
    return skip_pdf(pdf_path, "Could not create chapter for '#{filename}'") unless chapter

    # Check if PDF already linked
    existing_pdf = PdfMaterial.find_by(chapter: chapter, title: filename)
    if existing_pdf
      @skipped_count += 1
      puts "⏭️  Skipped: #{relative_path} (already linked)"
      return
    end

    # Create PDF material record
    begin
      # Use admin user for bulk imports
      admin_user = User.find_by(email: 'admin@aitutor.com') || User.where(role: 'admin').first

      pdf_material = PdfMaterial.new(
        title: filename,
        chapter: chapter,
        file_path: relative_path,
        user: admin_user
      )

      # Attach the PDF file from assets
      pdf_material.pdf_file.attach(
        io: File.open(pdf_path),
        filename: File.basename(pdf_path),
        content_type: 'application/pdf'
      )

      if pdf_material.save
        @imported_count += 1
        puts "✅ Imported: #{relative_path} → #{chapter.subject.grade.display_name} > #{chapter.subject.name} > #{chapter.name}"
      else
        @errors << "Failed to save PDF material for #{relative_path}: #{pdf_material.errors.full_messages.join(', ')}"
      end

    rescue => e
      @errors << "Error processing #{relative_path}: #{e.message}"
    end
  end

  def extract_grade_number(grade_folder)
    # Extract number from "class_10" → 10
    match = grade_folder.match(/class_(\d+)/)
    match ? match[1].to_i : nil
  end

  def find_matching_subject(grade, subject_folder)
    # Try direct name match first
    subject = grade.subjects.find_by("name ILIKE ?", subject_folder)
    return subject if subject

    # Try common mappings
    subject_mappings = {
      'maths' => 'Mathematics',
      'mathematics' => 'Mathematics',
      'maths_class_10' => 'Mathematics',
      'science' => 'Science',
      'science_class_10' => 'Science',
      'english' => 'English',
      'social_science' => 'Social Studies',
      'social_science_class_10' => 'Social Studies',
      'physics' => 'Physics',
      'chemistry' => 'Chemistry',
      'biology' => 'Biology',
      'computer_science' => 'Computer Science',
      'accountancy' => 'Accountancy',
      'business_studies' => 'Business Studies',
      'economics' => 'Economics',
      'geography' => 'Geography',
      'history' => 'History',
      'political_science' => 'Political Science',
      'psychology' => 'Psychology',
      'sociology' => 'Sociology',
      'informatics_practices' => 'Informatics Practices'
    }

    mapped_name = subject_mappings[subject_folder.downcase]
    if mapped_name
      grade.subjects.find_by("name ILIKE ?", mapped_name)
    else
      # Try partial match
      grade.subjects.find { |s| s.name.downcase.include?(subject_folder.downcase) }
    end
  end

  def find_or_create_chapter(subject, filename, pdf_path)
    # Try to find existing chapter by name
    chapter = subject.chapters.find_by("name ILIKE ?", filename)
    return chapter if chapter

    # Try variations of the filename
    variations = generate_chapter_name_variations(filename)
    variations.each do |variation|
      chapter = subject.chapters.find_by("name ILIKE ?", variation)
      return chapter if chapter
    end

    # Create new chapter if not found
    create_chapter_from_filename(subject, filename, pdf_path)
  end

  def generate_chapter_name_variations(filename)
    variations = [filename]

    # Handle common patterns
    if filename.match(/^ke\w+(\d+)$/) # e.g., keac101 → Chapter 101
      number = filename.match(/(\d+)$/)[1]
      variations << "Chapter #{number}"
    end

    if filename.match(/^\w+(\d+)$/) # e.g., math101 → Chapter 101
      number = filename.match(/(\d+)$/)[1]
      variations << "Chapter #{number}"
      variations << "Chapter #{number.to_i}" # Remove leading zeros
    end

    # Clean up filename
    clean_name = filename.gsub(/^ke\w+/, 'Chapter ').gsub(/_/, ' ').titleize
    variations << clean_name

    variations.uniq
  end

  def create_chapter_from_filename(subject, filename, pdf_path)
    # Generate a reasonable chapter name
    chapter_name = if filename.match(/^ke\w+(\d+)$/)
                     number = filename.match(/(\d+)$/)[1]
                     "Chapter #{number}"
                   else
                     filename.humanize.titleize
                   end

    # Create the chapter
    subject.chapters.create(
      name: chapter_name,
      description: "Chapter covering #{chapter_name.downcase} concepts."
    )
  end

  def skip_pdf(pdf_path, reason)
    @skipped_count += 1
    relative_path = pdf_path.gsub("#{@pdf_base_path}/", '')
    puts "⏭️  Skipped: #{relative_path} (#{reason})"
    false
  end
end
