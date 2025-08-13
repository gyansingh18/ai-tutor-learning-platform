class S3ListService
  def self.list(prefix:)
    resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: prefix)
    (resp.contents || []).map(&:key).reject { |k| k.end_with?("/") }
  end

  def self.list_by_grade(grade)
    list(prefix: "grade_#{grade}/")
  end

  def self.list_by_subject(grade, subject)
    list(prefix: "grade_#{grade}/#{subject.to_s.parameterize}/")
  end
end
