namespace :db do
  desc "Seed production database with comprehensive educational content"
  task seed_production: :environment do
    puts "=== Seeding Production Database with Educational Content ==="

    # Create grades if they don't exist
    grades = []
    grade_names = ["Grade 6", "Grade 7", "Grade 8", "Grade 9", "Grade 10", "Grade 11", "Grade 12"]

    grade_names.each do |grade_name|
      grade = Grade.find_or_create_by(name: grade_name) do |g|
        g.description = "#{grade_name} level education"
      end
      grades << grade
      puts "✓ Grade: #{grade.name}"
    end

    # Create subjects for each grade
    subjects_data = {
      "Grade 6" => ["Mathematics", "Science", "English", "Social Studies"],
      "Grade 7" => ["Mathematics", "Science", "English", "Social Studies"],
      "Grade 8" => ["Mathematics", "Science", "English", "Social Studies"],
      "Grade 9" => ["Mathematics", "Science", "English", "Social Studies"],
      "Grade 10" => ["Mathematics", "Science", "English", "Social Studies", "Computer Science", "Economics"],
      "Grade 11" => ["Mathematics", "Physics", "Chemistry", "Biology", "English", "History", "Geography", "Political Science", "Economics", "Computer Science", "Psychology", "Sociology", "Business Studies", "Accountancy"],
      "Grade 12" => ["Mathematics", "Physics", "Chemistry", "Biology", "English", "History", "Geography", "Political Science", "Economics", "Computer Science", "Psychology", "Sociology", "Business Studies", "Accountancy", "Informatics Practices"]
    }

    subjects_data.each do |grade_name, subject_names|
      grade = Grade.find_by(name: grade_name)
      next unless grade

      subject_names.each do |subject_name|
        subject = Subject.find_or_create_by(name: subject_name, grade: grade) do |s|
          s.description = "#{subject_name} for #{grade_name}"
        end
        puts "✓ Subject: #{subject.name} (#{grade.name})"

        # Create basic chapters for each subject
        create_basic_chapters(subject)
      end
    end

    puts "\n=== Final Counts ==="
    puts "Grades: #{Grade.count}"
    puts "Subjects: #{Subject.count}"
    puts "Chapters: #{Chapter.count}"

    puts "\n=== Production database seeded successfully! ==="
  end

  private

  def create_basic_chapters(subject)
    # Create basic chapters based on subject
    case subject.name.downcase
    when "mathematics"
      chapters = [
        "Numbers and Operations",
        "Algebra",
        "Geometry",
        "Statistics and Probability",
        "Calculus",
        "Trigonometry"
      ]
    when "science"
      chapters = [
        "Scientific Method",
        "Matter and Energy",
        "Forces and Motion",
        "Ecosystems",
        "Human Body",
        "Chemistry Basics"
      ]
    when "english"
      chapters = [
        "Reading Comprehension",
        "Grammar and Writing",
        "Literature Analysis",
        "Vocabulary Building",
        "Essay Writing",
        "Creative Writing"
      ]
    when "social studies"
      chapters = [
        "World History",
        "Geography",
        "Civics and Government",
        "Economics",
        "Cultural Studies",
        "Current Events"
      ]
    when "physics"
      chapters = [
        "Mechanics",
        "Thermodynamics",
        "Waves and Optics",
        "Electricity and Magnetism",
        "Modern Physics",
        "Nuclear Physics"
      ]
    when "chemistry"
      chapters = [
        "Atomic Structure",
        "Chemical Bonding",
        "Chemical Reactions",
        "Thermodynamics",
        "Organic Chemistry",
        "Analytical Chemistry"
      ]
    when "biology"
      chapters = [
        "Cell Biology",
        "Genetics",
        "Evolution",
        "Ecology",
        "Human Biology",
        "Plant Biology"
      ]
    when "computer science"
      chapters = [
        "Programming Fundamentals",
        "Data Structures",
        "Algorithms",
        "Database Systems",
        "Web Development",
        "Software Engineering"
      ]
    else
      # Generic chapters for other subjects
      chapters = [
        "Introduction to #{subject.name}",
        "Core Concepts",
        "Advanced Topics",
        "Applications",
        "Research Methods",
        "Current Trends"
      ]
    end

    chapters.each_with_index do |chapter_name, index|
      chapter = Chapter.find_or_create_by(name: chapter_name, subject: subject) do |c|
        c.description = "#{chapter_name} chapter for #{subject.name}"
      end
      puts "  ✓ Chapter: #{chapter.name}"
    end
  end
end
