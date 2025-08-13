class S3PdfService
  def self.list_pdfs_by_grade(grade)
    prefix = "grade_#{grade}/"
    list_pdfs_by_prefix(prefix)
  end

  def self.list_pdfs_by_subject(grade, subject)
    prefix = "grade_#{grade}/#{subject.to_s.parameterize}/"
    list_pdfs_by_prefix(prefix)
  end

  def self.list_pdfs_by_prefix(prefix)
    resp = S3_CLIENT.list_objects_v2(bucket: S3_BUCKET, prefix: prefix)
    (resp.contents || []).map(&:key).reject { |k| k.end_with?("/") }
  end

  def self.pdf_exists?(key)
    S3_CLIENT.head_object(bucket: S3_BUCKET, key: key)
    true
  rescue Aws::S3::Errors::NotFound
    false
  end

  def self.get_pdf_url(key, expires_in: 3600)
    if S3_PUBLIC
      "https://#{S3_BUCKET}.s3.#{S3_REGION}.amazonaws.com/#{key}"
    else
      signer = Aws::S3::Presigner.new(client: S3_CLIENT)
      signer.presigned_url(:get_object, bucket: S3_BUCKET, key: key, expires_in: expires_in)
    end
  end

  def self.upload_pdf(key, file_path)
    S3_CLIENT.put_object(
      bucket: S3_BUCKET,
      key: key,
      body: File.read(file_path),
      content_type: 'application/pdf'
    )
  end
end
