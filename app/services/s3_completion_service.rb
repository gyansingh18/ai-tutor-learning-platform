class S3CompletionService
  def complete_missing_vector_chunks
    puts "=== COMPLETING MISSING VECTOR CHUNKS ==="

    # Find chapters without vector chunks
    chapters_without_chunks = Chapter.left_joins(:vector_chunks)
                                   .where(vector_chunks: { id: nil })
                                   .includes(:subject)

    puts "Found #{chapters_without_chunks.count} chapters without vector chunks"

    if chapters_without_chunks.empty?
      puts "✅ All chapters already have vector chunks!"
      return
    end

    # Group by grade for better organization
    chapters_by_grade = chapters_without_chunks.group_by { |chapter| chapter.subject.grade }

    total_created = 0

    chapters_by_grade.each do |grade, chapters|
      puts "\n📚 Processing Grade #{grade.name} (#{chapters.count} chapters)"

      chapters.each do |chapter|
        puts "  📖 Processing: #{chapter.subject.name} > #{chapter.name}"

        # Find PDF material for this chapter
        pdf_material = PdfMaterial.find_by(chapter: chapter)

        if pdf_material&.file_path.present?
          begin
            chunks_created = create_vector_chunks_for_chapter(chapter, pdf_material)
            total_created += chunks_created
            puts "    ✅ Created #{chunks_created} vector chunks"
          rescue => e
            puts "    ❌ Error: #{e.message}"
          end
        else
          puts "    ⚠️  No PDF material found for this chapter"
        end
      end
    end

    puts "\n🎉 COMPLETION FINISHED!"
    puts "Total new vector chunks created: #{total_created}"
    puts "All chapters now have vector chunks!"
  end

  private

  def create_vector_chunks_for_chapter(chapter, pdf_material)
    # Use the existing S3PdfProcessorService to create chunks
    processor = S3PdfProcessorService.new(pdf_material)
    processor.process

    # Return the count of chunks created
    chapter.reload.vector_chunks.count
  end
end
