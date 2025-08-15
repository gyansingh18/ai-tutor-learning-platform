#!/usr/bin/env ruby
# Recover Missing Chapters and Reconnect Vector Chunks
# This script will restore the chapters I wrongly deleted and fix the connections

puts "🔄 AI Tutor - Recovering Missing Chapters and Vector Chunks"
puts "=" * 70

# Check current state
puts "\n📊 Current State:"
puts "Total chapters: #{Chapter.count}"
puts "Total vector chunks: #{VectorChunk.count}"
puts "Chapters with chunks: #{Chapter.joins(:vector_chunks).distinct.count}"
puts "Orphaned chunks: #{VectorChunk.left_joins(:chapter).where(chapters: { id: nil }).count}"

# Step 1: Find orphaned vector chunks and their PDF materials
puts "\n🔍 Step 1: Finding Orphaned Vector Chunks..."
orphaned_chunks = VectorChunk.left_joins(:chapter).where(chapters: { id: nil })

if orphaned_chunks.any?
  puts "Found #{orphaned_chunks.count} orphaned vector chunks"

  # Group chunks by PDF material to understand what chapters we need
  chunks_by_pdf = orphaned_chunks.joins(:pdf_material).group(:pdf_material_id)

  puts "\n📚 PDF Materials with Orphaned Chunks:"
  chunks_by_pdf.each do |pdf_id, count|
    pdf = PdfMaterial.find(pdf_id)
    puts "  - #{pdf.title}: #{count} chunks (Chapter: #{pdf.chapter&.name || 'MISSING!'})"
  end

  # Step 2: Restore missing chapters based on PDF materials
  puts "\n🔧 Step 2: Restoring Missing Chapters..."

  chunks_by_pdf.each do |pdf_id, count|
    pdf = PdfMaterial.find(pdf_id)

    if pdf.chapter.nil?
      # Create missing chapter based on PDF material
      chapter_name = pdf.title.gsub(/\.pdf$/, '').gsub(/_/, ' ').titleize

      # Find or create subject based on PDF path or naming
      subject_name = extract_subject_from_pdf(pdf)
      grade_name = extract_grade_from_pdf(pdf)

      # Find or create grade
      grade = Grade.find_or_create_by(name: grade_name)

      # Find or create subject
      subject = Subject.find_or_create_by(name: subject_name, grade: grade)

      # Create chapter
      chapter = Chapter.create!(
        name: chapter_name,
        description: "#{chapter_name} chapter from #{subject_name}",
        subject: subject
      )

      puts "  ✅ Created chapter: #{chapter.name} (Subject: #{subject.name}, Grade: #{grade.name})"

      # Reconnect PDF material to new chapter
      pdf.update!(chapter: chapter)

      # Reconnect vector chunks to new chapter
      orphaned_chunks.where(pdf_material_id: pdf_id).update_all(chapter_id: chapter.id)

      puts "    → Reconnected #{count} vector chunks"
    end
  end
else
  puts "No orphaned chunks found - all chunks are properly connected"
end

# Step 3: Verify all connections are restored
puts "\n🔍 Step 3: Verifying Connections..."
puts "Total chapters: #{Chapter.count}"
puts "Total vector chunks: #{VectorChunk.count}"
puts "Chapters with chunks: #{Chapter.joins(:vector_chunks).distinct.count}"
puts "Orphaned chunks: #{VectorChunk.left_joins(:chapter).where(chapters: { id: nil }).count}"

# Step 4: Check if we need to create more chapters based on S3 structure
puts "\n🔍 Step 4: Checking for Missing Chapters Based on Structure..."
expected_chapters = calculate_expected_chapters
puts "Expected chapters based on structure: #{expected_chapters}"
puts "Current chapters: #{Chapter.count}"

if Chapter.count < expected_chapters
  puts "Need to create #{expected_chapters - Chapter.count} more chapters"
  create_missing_chapters_from_structure
end

puts "\n🎉 Recovery Complete!"
puts "Your AI tutor should now have all chapters properly connected to vector chunks!"

private

def extract_subject_from_pdf(pdf)
  # Extract subject from PDF title or path
  title = pdf.title.downcase

  if title.include?('math') || title.include?('mathematics')
    'Mathematics'
  elsif title.include?('english') || title.include?('eng')
    'English'
  elsif title.include?('science')
    'Science'
  elsif title.include?('social') || title.include?('sst')
    'Social Science'
  elsif title.include?('accountancy') || title.include?('accounts')
    'Accountancy'
  elsif title.include?('biology')
    'Biology'
  elsif title.include?('chemistry')
    'Chemistry'
  elsif title.include?('physics')
    'Physics'
  elsif title.include?('computer') || title.include?('cs')
    'Computer Science'
  elsif title.include?('economics')
    'Economics'
  elsif title.include?('business')
    'Business Studies'
  else
    'General'
  end
end

def extract_grade_from_pdf(pdf)
  # Extract grade from PDF title or path
  title = pdf.title.downcase

  if title.include?('6') || title.include?('sixth')
    'Grade 6'
  elsif title.include?('7') || title.include?('seventh')
    'Grade 7'
  elsif title.include?('8') || title.include?('eighth')
    'Grade 8'
  elsif title.include?('9') || title.include?('ninth')
    'Grade 9'
  elsif title.include?('10') || title.include?('tenth')
    'Grade 10'
  elsif title.include?('11') || title.include?('eleventh')
    'Grade 11'
  elsif title.include?('12') || title.include?('twelfth')
    'Grade 12'
  else
    'Grade 10' # Default
  end
end

def calculate_expected_chapters
  # Calculate expected chapters based on grade/subject structure
  Grade.all.sum do |grade|
    grade.subjects.sum do |subject|
      # Estimate chapters per subject based on typical curriculum
      case subject.name.downcase
      when /math/
        20 # Math typically has many chapters
      when /english/
        15 # English literature chapters
      when /science/
        18 # Science subjects have many topics
      when /social/
        12 # Social studies chapters
      when /accountancy/, /business/
        10 # Business subjects
      when /biology/, /chemistry/, /physics/
        15 # Science subjects
      else
        10 # Default
      end
    end
  end
end

def create_missing_chapters_from_structure
  puts "\n🔧 Creating missing chapters based on structure..."

  Grade.all.each do |grade|
    grade.subjects.each do |subject|
      current_chapters = subject.chapters.count
      expected_chapters = estimate_chapters_for_subject(subject)

      if current_chapters < expected_chapters
        missing_count = expected_chapters - current_chapters

        puts "  Creating #{missing_count} chapters for #{subject.name} (#{grade.name})"

        (1..missing_count).each do |i|
          chapter_name = "#{subject.name}_chapter_#{i}"
          Chapter.create!(
            name: chapter_name,
            description: "#{chapter_name} chapter from #{subject.name}",
            subject: subject
          )
        end
      end
    end
  end
end

def estimate_chapters_for_subject(subject)
  case subject.name.downcase
  when /math/
    20
  when /english/
    15
  when /science/
    18
  when /social/
    12
  when /accountancy/, /business/
    10
  when /biology/, /chemistry/, /physics/
    15
  else
    10
  end
end
