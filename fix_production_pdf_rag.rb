#!/usr/bin/env ruby
# Fix Production PDF RAG Issue
# This script will populate production database with vector chunks from PDFs

puts "🔧 AI Tutor Production PDF RAG Fix Starting..."
puts "=" * 60

# Check current state
puts "\n📊 Current State:"
puts "Vector chunks: #{VectorChunk.count}"
puts "PDF materials: #{PdfMaterial.count}"
puts "Chapters: #{Chapter.count}"
puts "Chapters with vector chunks: #{Chapter.joins(:vector_chunks).distinct.count}"

if VectorChunk.count > 0
  puts "\n✅ Vector chunks already exist. Checking if they're properly distributed..."

  # Check if chunks are evenly distributed
  chapters_with_chunks = Chapter.joins(:vector_chunks).distinct.count
  total_chapters = Chapter.count

  if chapters_with_chunks < (total_chapters * 0.1) # Less than 10% have chunks
    puts "⚠️  Only #{chapters_with_chunks}/#{total_chapters} chapters have vector chunks."
    puts "🔄 Will process remaining PDFs..."
  else
    puts "✅ Vector chunks are well distributed across chapters."
    puts "🎯 Testing RAG functionality..."

    # Test RAG
    test_chapter = Chapter.joins(:vector_chunks).first
    if test_chapter
      rag = RagService.new(test_chapter)
      answer = rag.answer_question("What is this chapter about?")
      if answer.include?("I'm sorry") || answer.length < 50
        puts "❌ RAG test failed. Will reprocess all PDFs."
      else
        puts "✅ RAG test passed! System should be working."
        puts "Test answer: #{answer[0..150]}..."
        exit 0
      end
    end
  end
end

puts "\n🚀 Processing PDFs to generate vector chunks..."

# Process all PDF materials
processed_count = 0
error_count = 0
total_pdfs = PdfMaterial.count

PdfMaterial.includes(:chapter).find_each.with_index do |pdf_material, index|
  begin
    puts "\n📄 Processing #{index + 1}/#{total_pdfs}: #{pdf_material.file_path || pdf_material.id}"

    # Skip if already has vector chunks (unless forced)
    existing_chunks = pdf_material.vector_chunks.count
    if existing_chunks > 0 && !ENV['FORCE_REPROCESS']
      puts "  ⏭️  Skipping - already has #{existing_chunks} chunks"
      next
    end

    # Process the PDF
    processor = PdfProcessorService.new(pdf_material)
    success = processor.process

    if success
      new_chunks = pdf_material.vector_chunks.count
      puts "  ✅ Success - Generated #{new_chunks} vector chunks"
      processed_count += 1
    else
      puts "  ❌ Failed to process PDF"
      error_count += 1
    end

    # Add small delay to avoid overwhelming OpenAI API
    sleep(0.5)

  rescue => e
    puts "  💥 Error processing PDF: #{e.message}"
    error_count += 1
  end
end

puts "\n" + "=" * 60
puts "🎉 Processing Complete!"
puts "📊 Final Stats:"
puts "  Processed PDFs: #{processed_count}"
puts "  Errors: #{error_count}"
puts "  Total vector chunks: #{VectorChunk.count}"
puts "  Chapters with chunks: #{Chapter.joins(:vector_chunks).distinct.count}"

# Test the system
puts "\n🧪 Testing RAG System..."
test_chapter = Chapter.joins(:vector_chunks).first

if test_chapter
  puts "Testing with chapter: #{test_chapter.name}"
  rag = RagService.new(test_chapter)

  test_questions = [
    "What is this chapter about?",
    "Explain the main concept",
    "Give me an example"
  ]

  test_questions.each do |question|
    puts "\n❓ Question: #{question}"
    answer = rag.answer_question(question)
    puts "💡 Answer: #{answer[0..150]}..."

    # Check if answer seems to reference content
    if answer.include?("Based on") || answer.include?("textbook") || answer.length > 100
      puts "  ✅ Answer appears to reference PDF content"
    else
      puts "  ⚠️  Answer may not be referencing PDF content"
    end
  end
else
  puts "❌ No chapters with vector chunks found!"
end

puts "\n🏁 Fix Complete! Your AI should now reference PDF content in answers."
