namespace :pdf do
  desc "Import all PDF files from assets directory into database"
  task import_all: :environment do
    puts "🚀 Starting bulk PDF import task..."

    service = BulkPdfImportService.new
    result = service.import_all

    puts "\n📊 Final Summary:"
    puts "✅ Successfully imported: #{result[:imported]} PDFs"
    puts "⏭️  Skipped (already linked): #{result[:skipped]} PDFs"
    puts "❌ Errors encountered: #{result[:errors].count}"

    if result[:errors].any?
      puts "\n🔍 Error details:"
      result[:errors].each_with_index do |error, index|
        puts "#{index + 1}. #{error}"
      end
    end

    puts "\n✨ PDF import task completed!"
  end

  desc "Show PDF import statistics"
  task stats: :environment do
    puts "📊 PDF Import Statistics"
    puts "=" * 50

    # Physical files
    pdf_files = Dir.glob(Rails.root.join('app', 'assets', 'pdfs', '**', '*.pdf'))
    puts "📁 Physical PDF files: #{pdf_files.count}"

    # Database records
    db_pdfs = PdfMaterial.count
    puts "🗄️  Database PDF records: #{db_pdfs}"

    # Coverage
    coverage = db_pdfs.to_f / pdf_files.count * 100
    puts "📈 Coverage: #{coverage.round(2)}%"

    puts "\n📋 Breakdown by grade:"
    (6..12).each do |grade_num|
      grade_files = Dir.glob(Rails.root.join('app', 'assets', 'pdfs', "class_#{grade_num}", '**', '*.pdf'))
      grade = Grade.find_by("name ILIKE ? OR name ILIKE ?", "Grade #{grade_num}", "Class #{grade_num}")

      if grade
        linked_pdfs = PdfMaterial.joins(chapter: { subject: :grade }).where(grades: { id: grade.id }).count
        puts "   Grade #{grade_num}: #{linked_pdfs}/#{grade_files.count} PDFs linked"
      else
        puts "   Grade #{grade_num}: 0/#{grade_files.count} PDFs linked (grade not found)"
      end
    end
  end

  desc "Test import for a specific grade (e.g., rake pdf:test_grade[10])"
  task :test_grade, [:grade_number] => :environment do |task, args|
    grade_number = args[:grade_number] || '10'
    puts "🧪 Testing PDF import for Grade #{grade_number}..."

    pdf_files = Dir.glob(Rails.root.join('app', 'assets', 'pdfs', "class_#{grade_number}", '**', '*.pdf'))
    puts "📄 Found #{pdf_files.count} PDFs for Grade #{grade_number}"

    # Import just a few for testing
    test_files = pdf_files.first(5)
    puts "🔬 Testing with first #{test_files.count} files:"

    service = BulkPdfImportService.new
    test_files.each do |pdf_path|
      service.send(:import_single_pdf, pdf_path)
    end
  end

  desc "Clean up duplicate PDF records"
  task cleanup_duplicates: :environment do
    puts "🧹 Cleaning up duplicate PDF records..."

    duplicates = PdfMaterial.group(:title, :chapter_id).having('COUNT(*) > 1')
    puts "Found #{duplicates.count} sets of duplicates"

    duplicates.each do |group|
      records = PdfMaterial.where(title: group.title, chapter_id: group.chapter_id)
      keep = records.first
      remove = records.offset(1)

      puts "Keeping #{keep.title} (ID: #{keep.id}), removing #{remove.count} duplicates"
      remove.destroy_all
    end

    puts "✅ Duplicate cleanup completed!"
  end
end
