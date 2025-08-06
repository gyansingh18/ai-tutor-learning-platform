#!/usr/bin/env ruby

# Test the get_learning_progress method
require_relative 'config/environment'

# Create a test controller instance
controller = UsersController.new

# Mock the current_user method
def controller.current_user
  User.first
end

# Test the method
begin
  result = controller.send(:get_learning_progress)
  puts "Success! Result type: #{result.class}"
  puts "Result keys: #{result.keys}" if result.is_a?(Hash)
  puts "Result: #{result.inspect}"
rescue => e
  puts "Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5)}"
end
