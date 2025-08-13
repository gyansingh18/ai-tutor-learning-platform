namespace :s3 do
  desc "One-time initialization of grades, subjects, and chapters from S3 bucket"
  task initialize_data: :environment do
    puts "🚀 Starting S3 data initialization..."
    
    # Clear cache to ensure fresh data
    Rails.cache.clear
    
    # Include S3 helper methods
    include S3Helper
    
    # Define helper methods for S3 scanning
    def get_real_grades_from_s3
      begin
        puts "📂 Scanning S3 bucket for grade folders..."
        response = S3_CLIENT.list_objects_v2(
          bucket: S3_BUCKET,
          prefix: 'pdfs/',
          delimiter: '/'
        )
        
        grades = []
        (response.common_prefixes || []).each do |prefix|
          folder_name = prefix.prefix.split('/')[1] # Extract folder name after 'pdfs/'
          next unless folder_name
          
          # Extract grade number from "class_X" format
          if folder_name.match(/^class_(\d+)$/)
            grade_number = $1
            grades << grade_number
            puts "  ✅ Found grade: #{grade_number}"
          end
        end
        
        grades.sort_by(&:to_i)
      rescue => e
        puts "❌ Error getting grades from S3: #{e.message}"
        []
      end
    end
    
    def get_real_subjects_from_s3(grade_number)
      begin
        puts "📚 Getting subjects for grade #{grade_number}..."
        prefix = "pdfs/class_#{grade_number}/"
        response = S3_CLIENT.list_objects_v2(
          bucket: S3_BUCKET,
          prefix: prefix,
          delimiter: '/'
        )
        
        subjects = []
        (response.common_prefixes || []).each do |prefix|
          folder_name = prefix.prefix.split('/')[2] # Extract subject folder name
          next unless folder_name
          
          subject_name = folder_name.humanize.titleize
          subjects << subject_name
          puts "  ✅ Found subject: #{subject_name}"
        end
        
        subjects.sort
      rescue => e
        puts "❌ Error getting subjects from S3: #{e.message}"
        []
      end
    end
    
    def get_real_chapters_from_s3(grade_number, subject_name)
      begin
        subject_folder = subject_name.parameterize.underscore
        prefix = "pdfs/class_#{grade_number}/#{subject_folder}/"
        puts "📖 Getting chapters for #{subject_name} (#{prefix})..."
        
        response = S3_CLIENT.list_objects_v2(
          bucket: S3_BUCKET,
          prefix: prefix
        )
        
        chapters = []
        (response.contents || []).each do |object|
          next if object.key.end_with?('/')
          
          filename = File.basename(object.key, '.pdf')
          next if filename.blank?
          
          # Convert filename to readable chapter name
          if filename.match(/^(\w+)(\d+)$/)
            # Handle format like "keph101" -> "Keph 101"
            chapter_name = "#{$1.capitalize} #{$2}"
          elsif filename.match(/^chapter_?(\d+)$/i)
            # Handle "chapter1" or "chapter_1"
            chapter_num = $1.to_i
            chapter_name = "Chapter #{chapter_num}"
          elsif filename.match(/^(\d+)$/)
            # Handle pure numbers like "101"
            chapter_num = $1.to_i
            chapter_name = "Chapter #{chapter_num}"
          else
            # Use the actual filename as chapter name
            chapter_name = filename.humanize.titleize
          end
          
          chapters << chapter_name
        end
        
        # Remove duplicates and sort
        chapters.uniq.sort_by do |ch|
          # Sort by number if possible, otherwise alphabetically
          if ch.match(/(\d+)/)
            $1.to_i
          else
            ch
          end
        end
      rescue => e
        puts "❌ Error getting chapters from S3: #{e.message}"
        []
      end
    end
    
    # Start the initialization process
    total_grades = 0
    total_subjects = 0
    total_chapters = 0
    
    real_grades = get_real_grades_from_s3
    puts "🎯 Found #{real_grades.length} grades to process"
    
    real_grades.each do |grade_number|
      puts "\n🔄 Processing Grade #{grade_number}..."
      
      grade = Grade.find_or_create_by(name: "Grade #{grade_number}") do |g|
        g.description = "Grade #{grade_number} content"
      end
      total_grades += 1
      puts "  ✅ Grade: #{grade.name} (ID: #{grade.id})"
      
      real_subjects = get_real_subjects_from_s3(grade_number)
      puts "  📚 Found #{real_subjects.length} subjects"
      
      real_subjects.each do |subject_name|
        subject = Subject.find_or_create_by(name: subject_name, grade: grade) do |s|
          s.description = "#{subject_name} for #{grade.name}"
        end
        total_subjects += 1
        puts "    ✅ Subject: #{subject.name} (ID: #{subject.id})"
        
        real_chapters = get_real_chapters_from_s3(grade_number, subject_name)
        puts "    📖 Found #{real_chapters.length} chapters"
        
        real_chapters.each do |chapter_name|
          chapter = Chapter.find_or_create_by(name: chapter_name, subject: subject) do |c|
            c.description = "#{chapter_name} content"
          end
          total_chapters += 1
          puts "      ✅ Chapter: #{chapter.name} (ID: #{chapter.id})"
        end
      end
    end
    
    puts "\n🎉 S3 Data Initialization Complete!"
    puts "📊 Summary:"
    puts "  - Grades: #{total_grades}"
    puts "  - Subjects: #{total_subjects}"
    puts "  - Chapters: #{total_chapters}"
    puts "\n💡 Cache cleared. Next page loads will be fast!"
  end
end