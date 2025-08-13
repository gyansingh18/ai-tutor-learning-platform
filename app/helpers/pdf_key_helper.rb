module PdfKeyHelper
  # builds keys like "grade_7/math/ch1.pdf"
  def pdf_key(grade:, subject:, chapter:)
    "grade_#{grade}/#{subject.to_s.parameterize}/ch#{chapter}.pdf"
  end

  # Alternative: build from existing data
  def pdf_key_from_data(grade_name, subject_name, chapter_name)
    grade_num = grade_name.to_s.match(/\d+/).to_s
    "grade_#{grade_num}/#{subject_name.to_s.parameterize}/#{chapter_name.to_s.parameterize}.pdf"
  end
end
