module S3Helper
  # Public URL (used only if S3_PUBLIC = true)
  def s3_public_url(key)
    "https://#{S3_BUCKET}.s3.#{S3_REGION}.amazonaws.com/#{key}"
  end

  # Default: private presigned URL
  def s3_signed_url(key, expires_in: 3600)
    return s3_public_url(key) if S3_PUBLIC
    signer = Aws::S3::Presigner.new(client: S3_CLIENT)
    signer.presigned_url(:get_object, bucket: S3_BUCKET, key: key, expires_in: expires_in)
  end
end
