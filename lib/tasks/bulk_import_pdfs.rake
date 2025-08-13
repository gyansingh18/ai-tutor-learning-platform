namespace :pdfs do
  desc "Bulk import and process PDFs from S3 to create vector chunks"
  task bulk_import: :environment do
    puts "🚀 Starting bulk PDF import from S3..."
    puts

    # Include S3 helper methods
    include S3Helper

    # Initialize counters
    total_processed = 0
    total_chunks = 0
    errors = []

    # Get all PDF files from S3
    puts "📂 Scanning S3 bucket for PDFs..."
    s3_objects = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: 'pdfs/')
    pdf_files = s3_objects.contents.select { |obj| obj.key.end_with?('.pdf') }

    puts "Found #{pdf_files.count} PDF files in S3"
    puts

    pdf_files.each_with_index do |s3_object, index|
      begin
        puts "[#{index + 1}/#{pdf_files.count}] Processing: #{s3_object.key}"

        # Parse S3 key to extract grade, subject, chapter info
        # Format: pdfs/class_X/subject_name/chapter_file.pdf
        key_parts = s3_object.key.split('/')
        next if key_parts.length < 4

        grade_folder = key_parts[1]  # e.g., "class_10"
        subject_folder = key_parts[2] # e.g., "Science Class 10"
        chapter_filename = key_parts[3] # e.g., "Lesc105.pdf"

        # Extract grade number
        grade_match = grade_folder.match(/class_(\d+)/)
        next unless grade_match
        grade_number = grade_match[1]

        # Find or create grade
        grade = Grade.find_or_create_by(name: "Grade #{grade_number}") do |g|
          g.description = "Grade #{grade_number} content"
        end

        # Find or create subject
        subject = Subject.find_or_create_by(name: subject_folder, grade: grade) do |s|
          s.description = "#{subject_folder} for #{grade.name}"
        end

        # Extract chapter name from filename (remove .pdf extension)
        chapter_name = File.basename(chapter_filename, '.pdf')

        # Find or create chapter
        chapter = Chapter.find_or_create_by(name: chapter_name, subject: subject) do |c|
          c.description = "#{chapter_name} chapter from #{subject.name}"
        end

        # Check if PDF material already exists for this chapter
        existing_pdf = chapter.pdf_materials.find_by(title: chapter_name)
        if existing_pdf
          puts "  ⚠️  PDF already exists for #{chapter.name}, skipping..."
          next
        end

        # Create PDF material
        pdf_material = PdfMaterial.new(
          title: chapter_name,
          chapter: chapter,
          user: nil  # Bulk import, no specific user
        )

        # Download PDF from S3 and attach it
        puts "  📥 Downloading PDF from S3..."
        pdf_data = S3_CLIENT.get_object(bucket: S3_BUCKET, key: s3_object.key).body.read

        pdf_material.pdf_file.attach(
          io: StringIO.new(pdf_data),
          filename: chapter_filename,
          content_type: 'application/pdf'
        )

        if pdf_material.save
          puts "  ✅ PDF material created: #{pdf_material.title}"

          # Process PDF to create vector chunks
          puts "  🔄 Processing PDF to create vector chunks..."
          processor = PdfProcessorService.new(pdf_material)

          if processor.process
            chunk_count = pdf_material.vector_chunks.count
            puts "  ✅ Created #{chunk_count} vector chunks"
            total_chunks += chunk_count
          else
            puts "  ❌ Failed to process PDF into chunks"
            errors << "Failed to process #{s3_object.key} into chunks"
          end

          total_processed += 1
        else
          puts "  ❌ Failed to save PDF material: #{pdf_material.errors.full_messages.join(', ')}"
          errors << "Failed to save #{s3_object.key}: #{pdf_material.errors.full_messages.join(', ')}"
        end

      rescue => e
        puts "  ❌ Error processing #{s3_object.key}: #{e.message}"
        errors << "Error processing #{s3_object.key}: #{e.message}"
      end

      puts

      # Add a small delay to avoid overwhelming the OpenAI API
      sleep(0.5) if index % 10 == 0
    end

    puts "🎉 Bulk import completed!"
    puts "📊 Summary:"
    puts "  Total PDFs processed: #{total_processed}"
    puts "  Total vector chunks created: #{total_chunks}"
    puts "  Errors: #{errors.count}"

    if errors.any?
      puts
      puts "❌ Errors encountered:"
      errors.each { |error| puts "  - #{error}" }
    end

    puts
    puts "✅ RAG system is now ready for question answering!"
  end

  desc "Check status of PDF processing"
  task status: :environment do
    puts "📊 PDF Processing Status:"
    puts "  Total chapters: #{Chapter.count}"
    puts "  Chapters with PDFs: #{Chapter.joins(:pdf_materials).distinct.count}"
    puts "  Total PDF materials: #{PdfMaterial.count}"
    puts "  Total vector chunks: #{VectorChunk.count}"
    puts

    # Show sample chapters with PDF counts
    puts "Sample chapters with PDFs:"
    Chapter.joins(:pdf_materials).includes(:pdf_materials, :vector_chunks)
           .limit(10).each do |chapter|
      chunk_count = chapter.vector_chunks.count
      puts "  #{chapter.name}: #{chapter.pdf_materials.count} PDFs, #{chunk_count} chunks"
    end
  end
end
