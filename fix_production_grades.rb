#!/usr/bin/env ruby

# This script will be run on Heroku to fix the grade selection issue

puts "=== Checking Production Database ==="

# Check current status
puts "Grades count: #{Grade.count}"
puts "Subjects count: #{Subject.count}"
puts "Chapters count: #{Chapter.count}"

if Grade.count == 0
  puts "\n=== No grades found! Creating basic grade structure ==="
  
  # Create basic grades
  grades = [
    { name: "Grade 6", description: "Sixth grade level" },
    { name: "Grade 7", description: "Seventh grade level" },
    { name: "Grade 8", description: "Eighth grade level" },
    { name: "Grade 9", description: "Ninth grade level" },
    { name: "Grade 10", description: "Tenth grade level" },
    { name: "Grade 11", description: "Eleventh grade level" },
    { name: "Grade 12", description: "Twelfth grade level" }
  ]
  
  grades.each do |grade_attrs|
    grade = Grade.create!(grade_attrs)
    puts "✓ Created: #{grade.name}"
  end
  
  puts "\n=== Associating subjects with grades ==="
  
  # Get all subjects and associate them with grades
  subjects = Subject.all
  subjects.each_with_index do |subject, index|
    grade_index = index % Grade.count
    grade = Grade.offset(grade_index).first
    subject.update!(grade: grade)
    puts "✓ Associated #{subject.name} with #{grade.name}"
  end
  
else
  puts "\n=== Grades exist, checking associations ==="
  Grade.all.each do |grade|
    subject_count = grade.subjects.count
    puts "  - #{grade.name}: #{subject_count} subjects"
  end
  
  # Check if subjects have grades
  subjects_without_grades = Subject.where(grade_id: nil).count
  puts "\nSubjects without grades: #{subjects_without_grades}"
  
  if subjects_without_grades > 0
    puts "=== Fixing subject-grade associations ==="
    Subject.where(grade_id: nil).each_with_index do |subject, index|
      grade_index = index % Grade.count
      grade = Grade.offset(grade_index).first
      subject.update!(grade: grade)
      puts "✓ Associated #{subject.name} with #{grade.name}"
    end
  end
end

puts "\n=== Final Status ==="
puts "Grades: #{Grade.count}"
puts "Subjects with grades: #{Subject.where.not(grade_id: nil).count}"
puts "Subjects without grades: #{Subject.where(grade_id: nil).count}"

puts "\n=== Testing Grade.ordered scope ==="
ordered_grades = Grade.ordered
puts "Ordered grades: #{ordered_grades.map(&:name).join(', ')}"

puts "\n=== Grade selection should now work! ===" 