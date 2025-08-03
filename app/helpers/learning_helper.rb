module LearningHelper
  def self.extract_explanation(content)
    # Extract the explanation part (before "Question:")
    if content.include?("Question:")
      content.split("Question:").first.strip
    else
      content
    end
  end

  def self.extract_question(content)
    # Extract the question part (between "Question:" and "Hint:")
    if content.include?("Question:") && content.include?("Hint:")
      question_section = content.split("Question:").last
      question_section.split("Hint:").first.strip
    elsif content.include?("Question:")
      content.split("Question:").last.split("Correct Answer:").first.strip
    else
      nil
    end
  end

  def self.extract_hint(content)
    # Extract the hint part (between "Hint:" and "Correct Answer:")
    if content.include?("Hint:") && content.include?("Correct Answer:")
      hint_section = content.split("Hint:").last
      hint_section.split("Correct Answer:").first.strip
    elsif content.include?("Hint:")
      content.split("Hint:").last.strip
    else
      nil
    end
  end

  def self.extract_options(content)
    # Extract multiple choice options
    options = []
    content.scan(/Option [A-D]: (.+)/).each do |match|
      options << match[0]
    end
    options
  end

  def self.extract_correct_answer(content)
    # Extract the correct answer
    if content.include?("Correct Answer:")
      content.split("Correct Answer:").last.strip
    else
      nil
    end
  end
end
