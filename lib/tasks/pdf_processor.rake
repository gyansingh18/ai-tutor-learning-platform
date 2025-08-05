namespace :pdfs do
  desc "Test PDF reading capabilities"
  task test: :environment do
    puts "🧪 Testing PDF Reading Capabilities..."

    test_service = PdfTestService.new
    test_service.test_pdf_reading

    puts "\n✅ PDF testing completed!"
  end

  desc "Test single PDF file"
  task :test_single, [:pdf_path] => :environment do |task, args|
    pdf_path = args[:pdf_path]

    if pdf_path.blank?
      puts "❌ Please specify a PDF path: rake pdfs:test_single[path/to/file.pdf]"
      exit 1
    end

    unless File.exist?(pdf_path)
      puts "❌ PDF file not found: #{pdf_path}"
      exit 1
    end

    puts "🧪 Testing single PDF: #{pdf_path}"

    test_service = PdfTestService.new
    test_service.test_single_pdf(pdf_path)

    puts "\n✅ Single PDF testing completed!"
  end

  desc "Process all PDFs and create chapters automatically"
  task process: :environment do
    puts "🔍 Starting PDF Auto-Processing..."

    processor = PdfAutoProcessorService.new
    processor.process_all_pdfs

    puts "\n✅ PDF processing completed!"
  end

  desc "Process single PDF file"
  task :process_single, [:pdf_path] => :environment do |task, args|
    pdf_path = args[:pdf_path]

    if pdf_path.blank?
      puts "❌ Please specify a PDF path: rake pdfs:process_single[path/to/file.pdf]"
      exit 1
    end

    unless File.exist?(pdf_path)
      puts "❌ PDF file not found: #{pdf_path}"
      exit 1
    end

    puts "🔍 Processing single PDF: #{pdf_path}"

    processor = PdfAutoProcessorService.new
    chapter = processor.process_single_pdf(pdf_path)

    if chapter
      puts "✅ Successfully created chapter: #{chapter.name}"
    else
      puts "❌ Failed to process PDF"
    end
  end

  desc "Process maths folder with all PDFs"
  task process_maths: :environment do
    puts "🔍 Processing Maths Folder..."

    maths_folder = Rails.root.join('app', 'assets', 'pdfs', 'class_10', 'maths_class_10 copy')

    if Dir.exist?(maths_folder)
      processor = PdfAutoProcessorService.new
      processor.process_maths_folder(maths_folder.to_s)
      puts "\n✅ Maths folder processing completed!"
    else
      puts "❌ Maths folder not found: #{maths_folder}"
      puts "📁 Available folders:"
      Dir.glob(Rails.root.join('app', 'assets', 'pdfs', 'class_10', '*')).each do |folder|
        puts "  - #{File.basename(folder)}"
      end
    end
  end

  desc "Process single PDF from maths folder"
  task :process_maths_single, [:pdf_name] => :environment do |task, args|
    pdf_name = args[:pdf_name]

    if pdf_name.blank?
      puts "❌ Please specify a PDF name: rake pdfs:process_maths_single[jemh101.pdf]"
      exit 1
    end

    maths_folder = Rails.root.join('app', 'assets', 'pdfs', 'class_10', 'maths_class_10 copy')
    pdf_path = File.join(maths_folder, pdf_name)

    unless File.exist?(pdf_path)
      puts "❌ PDF file not found: #{pdf_path}"
      puts "📄 Available PDFs:"
      Dir.glob(File.join(maths_folder, '*.pdf')).each do |pdf|
        puts "  - #{File.basename(pdf)}"
      end
      exit 1
    end

    puts "🔍 Processing single PDF from maths folder: #{pdf_name}"

    processor = PdfAutoProcessorService.new
    grade = processor.send(:find_or_create_grade, "Grade 10")
    subject = processor.send(:find_or_create_subject, "Mathematics", grade)
    chapter = processor.process_single_pdf_with_subject(pdf_path, grade, subject)

    if chapter
      puts "✅ Successfully created chapter: #{chapter.name}"
    else
      puts "❌ Failed to process PDF"
    end
  end

  desc "Show current PDF directory structure"
  task structure: :environment do
    pdf_dir = Rails.root.join('app', 'assets', 'pdfs')

    puts "📁 Current PDF Directory Structure:"
    puts "Location: #{pdf_dir}"

    if Dir.exist?(pdf_dir)
      print_directory_tree(pdf_dir, "")
    else
      puts "❌ Directory does not exist. Creating structure..."
      FileUtils.mkdir_p(pdf_dir)
      puts "✅ Created: #{pdf_dir}"
    end
  end

  desc "Comprehensive analysis of all PDFs and structure"
  task analyze_all: :environment do
    puts "🔍 Starting comprehensive analysis..."

    processor = ComprehensivePdfProcessorService.new
    processor.analyze_all_structure
  end

  desc "Test all AI connections and systems"
  task test_ai: :environment do
    puts "🤖 Testing AI connections..."

    processor = ComprehensivePdfProcessorService.new
    processor.test_ai_connections
  end

  desc "Process all classes and subjects"
  task process_all: :environment do
    puts "🚀 Processing all classes and subjects..."

    processor = ComprehensivePdfProcessorService.new
    processor.process_all_classes
  end

  desc "Rename all PDFs intelligently"
  task rename_all: :environment do
    puts "📝 Renaming all PDFs intelligently..."

    processor = ComprehensivePdfProcessorService.new
    processor.rename_all_pdfs_intelligently
  end

  desc "Intelligently rename all entities (grades, subjects, chapters, PDFs)"
  task rename_entities: :environment do
    puts "🔄 Starting intelligent renaming..."

    service = IntelligentRenamingService.new
    service.rename_all_entities
  end

  desc "Generate renaming report"
  task renaming_report: :environment do
    puts "📊 Generating renaming report..."

    service = IntelligentRenamingService.new
    service.generate_renaming_report
  end

  desc "Rename only grades"
  task rename_grades: :environment do
    puts "📚 Renaming grades..."

    service = IntelligentRenamingService.new
    service.rename_grades
  end

  desc "Rename only subjects"
  task rename_subjects: :environment do
    puts "📖 Renaming subjects..."

    service = IntelligentRenamingService.new
    service.rename_subjects
  end

  desc "Rename only chapters"
  task rename_chapters: :environment do
    puts "📄 Renaming chapters..."

    service = IntelligentRenamingService.new
    service.rename_chapters
  end

  desc "Rename only PDF files"
  task rename_pdf_files: :environment do
    puts "📝 Renaming PDF files..."

    service = IntelligentRenamingService.new
    service.rename_pdf_files
  end

  desc "Batch rename all entities (faster, no PDF reading)"
  task batch_rename: :environment do
    puts "🔄 Starting batch renaming..."

    service = BatchRenamingService.new
    service.rename_in_batches
  end

  desc "Complete system analysis and test"
  task full_analysis: :environment do
    puts "🔍 COMPLETE SYSTEM ANALYSIS"
    puts "=" * 60

    processor = ComprehensivePdfProcessorService.new

    puts "\n1. 📊 STRUCTURE ANALYSIS"
    processor.analyze_all_structure

    puts "\n2. 🤖 AI CONNECTION TEST"
    processor.test_ai_connections

    puts "\n3. 📊 DATABASE ANALYSIS"
    puts "Grades: #{Grade.count}"
    puts "Subjects: #{Subject.count}"
    puts "Chapters: #{Chapter.count}"
    puts "PDF Materials: #{PdfMaterial.count}"
    puts "Vector Chunks: #{VectorChunk.count}"

    puts "\n✅ Complete analysis finished!"
  end

  desc "Fast PDF processing (no AI, filename patterns only)"
  task fast_process: :environment do
    puts "🚀 Starting fast PDF processing..."

    service = FastPdfProcessorService.new
    service.process_all_pdfs_fast
  end

  desc "Corrected PDF processing (proper path mapping)"
  task corrected_process: :environment do
    puts "🚀 Starting corrected PDF processing..."

    service = CorrectedPdfProcessorService.new
    service.process_all_pdfs_corrected
  end

  desc "Process PDFs with content reading (AI + filename patterns)"
  task content_reading: :environment do
    puts "📖 Starting PDF content reading..."

    service = PdfContentReaderService.new
    service.process_all_pdfs_with_content_reading
  end

  desc "Cleanup and reprocess with proper grade-subject filtering"
  task cleanup_reprocess: :environment do
    puts "🧹 Starting cleanup and reprocess..."

    service = CleanupAndReprocessService.new
    service.cleanup_and_reprocess
  end

  desc "Extract real chapter names from PDF content"
  task extract_chapter_names: :environment do
    puts "📖 Starting chapter name extraction..."

    service = PdfChapterExtractorService.new
    service.extract_real_chapter_names
  end

  desc "Test single PDF for chapter name extraction"
  task :test_pdf_chapter, [:pdf_path] => :environment do |t, args|
    if args[:pdf_path]
      puts "🧪 Testing PDF chapter extraction..."

      service = PdfChapterExtractorService.new
      service.test_single_pdf(args[:pdf_path])
    else
      puts "❌ Please provide a PDF path: rake pdfs:test_pdf_chapter[path/to/file.pdf]"
    end
  end

  desc "Extract chapter names from PDF text (simple approach)"
  task extract_chapter_names_simple: :environment do
    puts "📖 Starting simple chapter name extraction..."

    service = SimplePdfChapterExtractor.new
    service.extract_chapter_names_from_text
  end

  desc "Test single PDF for simple chapter extraction"
  task :test_simple_pdf_chapter, [:pdf_path] => :environment do |t, args|
    if args[:pdf_path]
      puts "🧪 Testing simple PDF chapter extraction..."

      service = SimplePdfChapterExtractor.new
      service.test_single_pdf(args[:pdf_path])
    else
      puts "❌ Please provide a PDF path: rake pdfs:test_simple_pdf_chapter[path/to/file.pdf]"
    end
  end

  private

  def print_directory_tree(path, prefix)
    Dir.entries(path).sort.each do |entry|
      next if entry.start_with?('.')

      full_path = File.join(path, entry)
      if File.directory?(full_path)
        puts "#{prefix}📁 #{entry}/"
        print_directory_tree(full_path, prefix + "  ")
      else
        puts "#{prefix}📄 #{entry}"
      end
    end
  end
end
