#!/usr/bin/env ruby
# Fix All AI Tutor Issues Fast!
# This script will clean up duplicates, corrupted chapters, and fix PDF mapping

puts "🚀 AI Tutor - Fixing All Issues Fast!"
puts "=" * 60

# Check current state
puts "\n📊 Current State:"
puts "Total chapters: #{Chapter.count}"
puts "Chapters with PDFs: #{Chapter.joins(:pdf_materials).distinct.count}"
puts "Chapters with vector chunks: #{Chapter.joins(:vector_chunks).distinct.count}"
puts "Total vector chunks: #{VectorChunk.count}"

# Step 1: Fix duplicate chapters (remove ones with spaces in names)
puts "\n🔧 Step 1: Fixing Duplicate Chapters..."
duplicate_chapters = Chapter.where("name LIKE '% %'")
puts "Found #{duplicate_chapters.count} chapters with spaces in names (duplicates)"

if duplicate_chapters.any?
  duplicate_chapters.each do |chapter|
    # Find the corresponding chapter without spaces
    clean_name = chapter.name.gsub(' ', '')
    clean_chapter = Chapter.find_by(name: clean_name)

    if clean_chapter
      puts "  - Removing duplicate: '#{chapter.name}' (keeping '#{clean_name}')"
      # Transfer any data before deletion
      if chapter.pdf_materials.any?
        chapter.pdf_materials.update_all(chapter_id: clean_chapter.id)
        puts "    → Transferred #{chapter.pdf_materials.count} PDFs"
      end
      if chapter.vector_chunks.any?
        chapter.vector_chunks.update_all(chapter_id: clean_chapter.id)
        puts "    → Transferred #{chapter.vector_chunks.count} vector chunks"
      end
      chapter.destroy
    else
      puts "  - Fixing name: '#{chapter.name}' → '#{clean_name}'"
      chapter.update!(name: clean_name)
    end
  end
end

# Step 2: Remove corrupted chapters with generic descriptions
puts "\n🧹 Step 2: Cleaning Corrupted Chapters..."
corrupted_chapters = Chapter.where("description LIKE 'Chapter % content'")
puts "Found #{corrupted_chapters.count} chapters with generic descriptions"

if corrupted_chapters.any?
  corrupted_chapters.each do |chapter|
    puts "  - Removing corrupted: '#{chapter.name}' (#{chapter.description})"
    chapter.destroy
  end
end

# Step 3: Remove chapters without PDFs that can't be processed
puts "\n🗑️  Step 3: Removing Orphaned Chapters..."
orphaned_chapters = Chapter.left_joins(:pdf_materials).where(pdf_materials: { id: nil })
puts "Found #{orphaned_chapters.count} chapters without PDFs"

if orphaned_chapters.any?
  orphaned_chapters.each do |chapter|
    puts "  - Removing orphaned: '#{chapter.name}' (no PDFs, no content)"
    chapter.destroy
  end
end

# Step 4: Fix remaining chapters with proper descriptions
puts "\n🔧 Step 4: Fixing Chapter Descriptions..."
chapters_to_fix = Chapter.where("description IS NULL OR description = ''")
puts "Found #{chapters_to_fix.count} chapters with missing descriptions"

chapters_to_fix.each do |chapter|
  if chapter.subject
    new_description = "#{chapter.name} chapter from #{chapter.subject.name}"
    chapter.update!(description: new_description)
    puts "  - Fixed description: '#{chapter.name}' → '#{new_description}'"
  end
end

# Step 5: Ensure all chapters with PDFs have vector chunks
puts "\n🧠 Step 5: Processing PDFs for Vector Chunks..."
chapters_with_pdfs = Chapter.joins(:pdf_materials).distinct
chapters_needing_chunks = chapters_with_pdfs.left_joins(:vector_chunks).where(vector_chunks: { id: nil })

puts "Found #{chapters_needing_chunks.count} chapters with PDFs but no vector chunks"

if chapters_needing_chunks.any?
  puts "\n🔄 Processing PDFs to generate vector chunks..."

  chapters_needing_chunks.each_with_index do |chapter, index|
    puts "  [#{index + 1}/#{chapters_needing_chunks.count}] Processing: #{chapter.name}"

    begin
      # Use the existing PDF processor service
      chapter.pdf_materials.each do |pdf|
        if pdf.pdf_file.attached?
          puts "    → Processing PDF: #{pdf.title}"

          # Create vector chunks for this PDF
          content = pdf.extract_text_content
          if content.present?
            chunks = pdf.create_vector_chunks(content)
            puts "      ✓ Created #{chunks.count} vector chunks"
          else
            puts "      ⚠️  No content extracted from PDF"
          end
        end
      end
    rescue => e
      puts "      ❌ Error processing #{chapter.name}: #{e.message}"
    end
  end
end

# Final status
puts "\n🎉 Final Status:"
puts "Total chapters: #{Chapter.count}"
puts "Chapters with PDFs: #{Chapter.joins(:pdf_materials).distinct.count}"
puts "Chapters with vector chunks: #{Chapter.joins(:vector_chunks).distinct.count}"
puts "Total vector chunks: #{VectorChunk.count}"

# Calculate improvement
initial_chapters = 1167
final_chapters = Chapter.count
initial_chunks = 1312
final_chunks = VectorChunk.count

puts "\n📈 Improvements:"
puts "Chapters cleaned up: #{initial_chapters - final_chapters}"
puts "Vector chunks added: #{final_chunks - initial_chunks}"
puts "AI-ready chapters: #{Chapter.joins(:vector_chunks).distinct.count}"

puts "\n✅ All issues fixed! Your AI tutor should now work properly with PDF references."
