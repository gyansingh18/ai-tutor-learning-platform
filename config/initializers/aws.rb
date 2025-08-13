# frozen_string_literal: true
require "aws-sdk-s3"

region  = Rails.application.credentials.dig(:aws, :region)  || ENV["AWS_REGION"]
bucket  = Rails.application.credentials.dig(:aws, :bucket)  || ENV["AWS_BUCKET"]
public_ = Rails.application.credentials.dig(:aws, :public)
public_ = ENV["AWS_PUBLIC"] == "true" if public_.nil?

Aws.config.update(
  region: region,
  credentials: Aws::Credentials.new(
    Rails.application.credentials.dig(:aws, :access_key_id)     || ENV["AWS_ACCESS_KEY_ID"],
    Rails.application.credentials.dig(:aws, :secret_access_key) || ENV["AWS_SECRET_ACCESS_KEY"]
  )
)

S3_CLIENT = Aws::S3::Client.new
S3_BUCKET = bucket
S3_REGION = region
S3_PUBLIC = !!public_
