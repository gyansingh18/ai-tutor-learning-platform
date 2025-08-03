# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample tasks for chapters
puts "Creating sample tasks..."

# Get the first chapter (Mathematics - Numbers and Operations)
chapter = Chapter.find_by(name: "Numbers and Operations")
if chapter
  # Task 1: Multiple Choice
  chapter.tasks.create!(
    title: "Understanding Numbers",
    content: "What is the smallest prime number?\n\nOption A: 0\nOption B: 1\nOption C: 2\nOption D: 3\n\nCorrect Answer: C",
    task_type: "multiple_choice",
    order: 1
  )

  # Task 2: Fill in the Blank
  chapter.tasks.create!(
    title: "Basic Addition",
    content: "Complete the following: 15 + 27 = ___\n\nThis is a simple addition problem. Add the two numbers together.",
    task_type: "fill_in_blank",
    order: 2
  )

  # Task 3: True/False
  chapter.tasks.create!(
    title: "Number Properties",
    content: "All even numbers are divisible by 2.\n\nThink about what makes a number even.\n\nCorrect Answer: True",
    task_type: "true_false",
    order: 3
  )

  # Task 4: Short Answer
  chapter.tasks.create!(
    title: "Number Patterns",
    content: "What comes next in the sequence: 2, 4, 8, 16, ___?\n\nLook at how each number relates to the previous one.",
    task_type: "short_answer",
    order: 4
  )
end

# Get the Algebra chapter
algebra_chapter = Chapter.find_by(name: "Algebra")
if algebra_chapter
  # Task 1: Coding (Simple equation solver)
  algebra_chapter.tasks.create!(
    title: "Simple Equation",
    content: "Write a function to solve the equation: 2x + 5 = 13\n\nYour function should return the value of x.\n\nExample:\ndef solve_equation\n  # Your code here\n  return x\nend",
    task_type: "coding",
    order: 1
  )

  # Task 2: Multiple Choice
  algebra_chapter.tasks.create!(
    title: "Variables",
    content: "What is a variable in algebra?\n\nOption A: A number that never changes\nOption B: A letter that represents an unknown value\nOption C: A mathematical symbol\nOption D: A type of equation\n\nCorrect Answer: B",
    task_type: "multiple_choice",
    order: 2
  )

  # Task 3: Fill in the Blank
  algebra_chapter.tasks.create!(
    title: "Solving for x",
    content: "If 3x = 15, then x = ___\n\nDivide both sides by 3 to solve for x.",
    task_type: "fill_in_blank",
    order: 3
  )
end

# Get the REAL NUMBERS chapter
real_numbers_chapter = Chapter.find_by(name: "REAL NUMBERS")
if real_numbers_chapter
  # Task 1: Multiple Choice
  real_numbers_chapter.tasks.create!(
    title: "Understanding Real Numbers",
    content: "Which of the following is NOT a real number?\n\nOption A: 3.14\nOption B: √2\nOption C: -5\nOption D: √(-1)\n\nCorrect Answer: D",
    task_type: "multiple_choice",
    order: 1
  )

  # Task 2: Fill in the Blank
  real_numbers_chapter.tasks.create!(
    title: "Rational vs Irrational",
    content: "Is √16 a rational or irrational number?\n\nThink about whether √16 can be expressed as a fraction.\n\nCorrect Answer: rational",
    task_type: "fill_in_blank",
    order: 2
  )

  # Task 3: True/False
  real_numbers_chapter.tasks.create!(
    title: "Number Properties",
    content: "All rational numbers are real numbers.\n\nThink about the relationship between rational and real numbers.\n\nCorrect Answer: True",
    task_type: "true_false",
    order: 3
  )

  # Task 4: Short Answer
  real_numbers_chapter.tasks.create!(
    title: "Number Classification",
    content: "Classify the number 0.333... (repeating decimal).\n\nIs it rational, irrational, or neither?",
    task_type: "short_answer",
    order: 4
  )

  # Task 5: Coding
  real_numbers_chapter.tasks.create!(
    title: "Number Validation",
    content: "Write a function to check if a number is rational.\n\nA rational number can be expressed as a fraction p/q where p and q are integers and q ≠ 0.\n\nExample:\ndef is_rational(number):\n  # Your code here\n  return True or False",
    task_type: "coding",
    order: 5
  )
end

puts "Sample tasks created successfully!"
