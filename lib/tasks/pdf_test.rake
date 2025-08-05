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
end
