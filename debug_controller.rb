#!/usr/bin/env ruby

puts "=== Debug Controller ==="

# Test S3 connection directly
begin
  require 'aws-sdk-s3'

  # Get S3 credentials from environment
  region = ENV['AWS_REGION'] || 'ap-south-1'
  bucket = ENV['AWS_BUCKET'] || 'ai-tutor-learning-platform'
  access_key = ENV['AWS_ACCESS_KEY_ID']
  secret_key = ENV['AWS_SECRET_ACCESS_KEY']

  puts "Region: #{region}"
  puts "Bucket: #{bucket}"
  puts "Access Key: #{access_key ? 'Set' : 'Not Set'}"
  puts "Secret Key: #{secret_key ? 'Set' : 'Not Set'}"

  if access_key && secret_key
    client = Aws::S3::Client.new(
      region: region,
      credentials: Aws::Credentials.new(access_key, secret_key)
    )

    puts "=== Testing S3 List ==="
    resp = client.list_objects_v2(bucket: bucket, delimiter: '/')

    puts "Common prefixes (folders):"
    resp.common_prefixes.each do |prefix|
      puts "  #{prefix.prefix}"
    end

    puts "\nFirst 10 objects:"
    resp.contents.first(10).each do |obj|
      puts "  #{obj.key}"
    end

  else
    puts "AWS credentials not set!"
  end

rescue => e
  puts "Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(3).join("\n")}"
end
