namespace :s3 do
  desc "Complete missing vector chunks for chapters that don't have them"
  task complete_missing_chunks: :environment do
    puts "Starting completion of missing vector chunks..."

    service = S3CompletionService.new
    service.complete_missing_vector_chunks

    puts "Task completed!"
  end
end




