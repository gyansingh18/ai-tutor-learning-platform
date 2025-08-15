class S3RebuildService
  def self.rebuild_from_s3_structure
    new.rebuild_from_s3_structure
  end

  def rebuild_from_s3_structure
    puts "Starting S3 structure rebuild..."

    # Clear existing data
    clear_existing_data

    # Discover new structure from S3
    grade_folders = discover_grade_folders
    puts "Found grade folders: #{grade_folders}"

    # Rebuild database structure
    rebuild_database_structure(grade_folders)

    # Create vector chunks for all PDFs
    create_vector_chunks

    puts "S3 structure rebuild completed!"
  end

  private

  def clear_existing_data
    puts "Clearing existing data..."

    # Delete in reverse dependency order to avoid foreign key violations
    puts "  Deleting vector chunks..."
    VectorChunk.delete_all

    puts "  Deleting student answers..."
    StudentAnswer.delete_all

    puts "  Deleting tasks..."
    Task.delete_all

    puts "  Deleting answers..."
    Answer.delete_all

    puts "  Deleting questions..."
    Question.delete_all

    puts "  Deleting PDF materials..."
    PdfMaterial.delete_all

    puts "  Deleting chapters..."
    Chapter.delete_all

    puts "  Deleting subjects..."
    Subject.delete_all

    puts "  Deleting grades..."
    Grade.delete_all

    puts "Existing data cleared"
  end

  def discover_grade_folders
    # List all objects in the pdfs/ prefix
    resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: "pdfs/")
    return [] unless resp.contents

    puts "  Found #{resp.contents.count} objects in pdfs/ prefix"

    # Extract unique grade names from object keys
    grade_folders = resp.contents
      .map(&:key)
      .map { |key| key.match(/^pdfs\/(class_\d+)\//) }
      .compact
      .map { |match| match[1] }
      .uniq
      .sort

    puts "  Extracted grade folders: #{grade_folders}"

    # Debug: show some sample keys
    puts "  Sample keys:"
    resp.contents.first(5).each do |obj|
      puts "    #{obj.key}"
    end

    grade_folders
  end

  def rebuild_database_structure(grade_folders)
    grade_folders.each do |grade_folder|
      grade_name = grade_folder.gsub('class_', '')
      puts "Processing grade: #{grade_name}"

      # Create grade
      grade = Grade.find_or_create_by!(name: grade_name) do |g|
        g.description = "Grade #{grade_name}"
      end

      # Discover subjects for this grade
      subjects = discover_subjects_for_grade(grade_folder)
      puts "  Found subjects: #{subjects}"

      subjects.each do |subject_name|
        puts "  Processing subject: #{subject_name}"

        # Create subject
        subject = Subject.find_or_create_by!(name: subject_name, grade: grade) do |s|
          s.description = "#{subject_name} for Grade #{grade_name}"
        end

        # Discover chapters for this subject
        chapters = discover_chapters_for_subject(grade_folder, subject_name)
        puts "    Found chapters: #{chapters}"

        chapters.each do |chapter_name|
          puts "    Processing chapter: #{chapter_name}"

          # Create chapter
          chapter = Chapter.find_or_create_by!(name: chapter_name, subject: subject) do |c|
            c.description = "#{chapter_name} chapter for #{subject_name}"
          end

          # Find the actual PDF file for this chapter
          pdf_key = find_pdf_file_for_chapter(grade_folder, subject_name, chapter_name)
          if pdf_key
            create_pdf_material(chapter, pdf_key)
          else
            puts "    Warning: No PDF file found for chapter #{chapter_name}"
          end
        end
      end
    end
  end

  def discover_subjects_for_grade(grade_folder)
    resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: "pdfs/#{grade_folder}/")
    return [] unless resp.contents

    puts "    Looking for subjects in #{grade_folder}, found #{resp.contents.count} objects"

    subjects = resp.contents
      .map(&:key)
      .map { |key| key.match(/^pdfs\/#{grade_folder}\/([^\/]+)\//) }
      .compact
      .map { |match| match[1] }
      .uniq
      .reject { |name| name.start_with?('.') }

    puts "    Extracted subjects: #{subjects}"
    subjects
  end

  def discover_chapters_for_subject(grade_folder, subject_name)
    resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: "pdfs/#{grade_folder}/#{subject_name}/")
    return [] unless resp.contents

    chapters = resp.contents
      .map(&:key)
      .select { |key| key.end_with?('.pdf') }
      .map { |key| key.match(/^pdfs\/#{grade_folder}\/#{subject_name}\/([^\/]+)\.pdf$/)[1] }
      .map { |name| name.gsub('_', ' ').titleize }
      .uniq
      .reject { |name| name.blank? }

    chapters
  end

  def create_pdf_material(chapter, pdf_key)
    # Check if PDF exists in S3
    begin
      S3_CLIENT.head_object(bucket: S3_BUCKET, key: pdf_key)
    rescue Aws::S3::Errors::NotFound
      puts "    Warning: PDF not found at #{pdf_key}"
      return nil
    end

    # Create PDF material record
    pdf_material = PdfMaterial.find_or_create_by!(file_path: pdf_key) do |pm|
      pm.chapter = chapter
      pm.title = chapter.name
    end

    puts "    Created PDF material: #{pdf_material.title}"
    pdf_material
  end

  def find_pdf_file_for_chapter(grade_folder, subject_name, chapter_name)
    # List all PDFs in the subject folder
    resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: "pdfs/#{grade_folder}/#{subject_name}/")
    return nil unless resp.contents

    # Find the PDF file that best matches the chapter name
    pdf_files = resp.contents.select { |obj| obj.key.end_with?('.pdf') }

    # Try exact match first
    exact_match = pdf_files.find { |obj| obj.key.include?(chapter_name) }
    return exact_match.key if exact_match

    # Try case-insensitive match
    case_insensitive_match = pdf_files.find { |obj| obj.key.downcase.include?(chapter_name.downcase) }
    return case_insensitive_match.key if case_insensitive_match

    # Try partial match
    partial_match = pdf_files.find { |obj|
      chapter_words = chapter_name.split(/\s+/)
      chapter_words.any? { |word| obj.key.include?(word) }
    }
    return partial_match.key if partial_match

    nil
  end

  def get_file_size(pdf_key)
    begin
      resp = S3_CLIENT.head_object(bucket: S3_BUCKET, key: pdf_key)
      resp.content_length
    rescue
      0
    end
  end

  def create_vector_chunks
    puts "Creating vector chunks..."

    PdfMaterial.includes(:chapter).find_each do |pdf_material|
      puts "Processing vector chunks for: #{pdf_material.title}"

      begin
        # Use S3 PDF processor service to create vector chunks
        S3PdfProcessorService.new(pdf_material).process
        puts "  Vector chunks created successfully"
      rescue => e
        puts "  Error creating vector chunks: #{e.message}"
      end
    end
  end
end
