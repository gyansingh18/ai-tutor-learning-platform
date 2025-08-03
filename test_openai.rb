#!/usr/bin/env ruby

require 'dotenv/load'
require 'ruby-openai'

# Load environment variables
Dotenv.load

# Check if API key is set
api_key = ENV['OPENAI_API_KEY']
if api_key.nil? || api_key == 'your_openai_api_key_here'
  puts "❌ OpenAI API key not found or not set!"
  puts "Please add your OpenAI API key to the .env file:"
  puts "OPENAI_API_KEY=your_actual_api_key_here"
  exit 1
end

puts "🔑 API Key found: #{api_key[0..10]}..."

# Initialize OpenAI client
client = OpenAI::Client.new(access_token: api_key)

begin
  puts "🧪 Testing OpenAI API..."
  
  # Test with a simple chat completion
  response = client.chat(
    parameters: {
      model: "gpt-3.5-turbo",
      messages: [
        { role: "user", content: "Say 'Hello from AI Tutor!' in a friendly way." }
      ],
      max_tokens: 50
    }
  )
  
  if response.dig("choices", 0, "message", "content")
    puts "✅ OpenAI API is working!"
    puts "Response: #{response.dig("choices", 0, "message", "content")}"
  else
    puts "❌ Unexpected response format"
    puts response.inspect
  end
  
rescue => e
  puts "❌ OpenAI API test failed:"
  puts "Error: #{e.message}"
  puts "Please check your API key and internet connection."
end 