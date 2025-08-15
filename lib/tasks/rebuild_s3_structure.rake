namespace :s3 do
  desc "Rebuild database structure from new S3 folder organization"
  task rebuild_structure: :environment do
    puts "Starting S3 structure rebuild..."

    begin
      S3RebuildService.rebuild_from_s3_structure
      puts "S3 structure rebuild completed successfully!"
    rescue => e
      puts "Error during S3 structure rebuild: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Test S3 connection and list available folders"
  task test_connection: :environment do
    puts "Testing S3 connection..."

    begin
      # Test listing objects in pdfs/ prefix
      puts "Listing objects in pdfs/ prefix..."
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: "pdfs/", max_keys: 10)

      if resp.contents&.any?
        puts "✓ S3 connection successful"
        puts "Found #{resp.contents.count} objects:"
        resp.contents.each do |obj|
          puts "  - #{obj.key}"
        end
      else
        puts "✓ S3 connection successful"
        puts "No objects found in pdfs/ prefix"
      end

      # Test specific grade folder
      puts "\nTesting class_6 folder..."
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: "pdfs/class_6/", max_keys: 5)

      if resp.contents&.any?
        puts "Found #{resp.contents.count} objects in grade_6:"
        resp.contents.each do |obj|
          puts "  - #{obj.key}"
        end
      else
        puts "No objects found in grade_6 folder"
      end

    rescue => e
      puts "✗ S3 connection failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Show current S3 folder structure"
  task show_structure: :environment do
    puts "Current S3 folder structure:"

    begin
      # List all objects in pdf/ prefix
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: "pdf/")

      if resp.contents&.any?
        # Group by grade
        grades = {}
        resp.contents.each do |obj|
          parts = obj.key.split('/')
          next if parts.length < 3

          grade = parts[1]
          subject = parts[2] if parts.length > 2
          chapter = parts[3] if parts.length > 3

          grades[grade] ||= {}
          grades[grade][subject] ||= []
          grades[grade][subject] << chapter if chapter
        end

        grades.each do |grade, subjects|
          puts "\n#{grade}:"
          subjects.each do |subject, chapters|
            puts "  #{subject}:"
            chapters.compact.uniq.each do |chapter|
              puts "    - #{chapter}"
            end
          end
        end
      else
        puts "No objects found in pdf/ prefix"
      end

    rescue => e
      puts "Error showing structure: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

  desc "List all available prefixes in S3 bucket"
  task list_prefixes: :environment do
    puts "Listing all available prefixes in S3 bucket:"

    begin
      # List all objects (limited to first 1000)
      resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, max_keys: 1000)

      if resp.contents&.any?
        # Group by prefix
        prefixes = {}
        resp.contents.each do |obj|
          parts = obj.key.split('/')
          prefix = parts[0]
          prefixes[prefix] ||= []
          prefixes[prefix] << obj.key
        end

        prefixes.each do |prefix, keys|
          puts "\n#{prefix}/ (#{keys.count} objects):"
          keys.first(5).each do |key|
            puts "  - #{key}"
          end
          puts "  ... and #{keys.count - 5} more" if keys.count > 5
        end
      else
        puts "No objects found in bucket"
      end

    rescue => e
      puts "Error listing prefixes: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
