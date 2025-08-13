# S3 PDF Storage Setup for AI Tutor

This guide will help you configure AWS S3 for PDF storage in your AI Tutor application.

## Prerequisites

1. AWS Account with S3 access
2. IAM user with S3 permissions
3. S3 bucket created in your preferred region

## Setup Steps

### 1. AWS Credentials (Development)

Edit your Rails credentials:
```bash
EDITOR="nano" bin/rails credentials:edit
```

Add the following (replace with your actual values):
```yaml
aws:
  access_key_id: YOUR_ACCESS_KEY_ID
  secret_access_key: YOUR_SECRET_ACCESS_KEY
  region: ap-south-1
  bucket: ai-tutor-learning-platform
  public: false
```

### 2. Heroku Environment Variables (Production)

Set the following environment variables on Heroku:
```bash
heroku config:set \
AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID \
AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY \
AWS_REGION=ap-south-1 \
AWS_BUCKET=ai-tutor-learning-platform \
AWS_PUBLIC=false
```

### 3. S3 Bucket Configuration

#### CORS Configuration
Add this CORS configuration to your S3 bucket:

```xml
<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>http://localhost:3000</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>HEAD</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
  </CORSRule>
  <CORSRule>
    <AllowedOrigin>https://your-heroku-app.herokuapp.com</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>HEAD</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
  </CORSRule>
</CORSConfiguration>
```

#### Bucket Policy (if using public access)
If you want public PDF access, add this bucket policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

### 4. Test S3 Configuration

Run the test script to verify everything is working:
```bash
ruby test_s3.rb
```

### 5. PDF Organization Structure

Organize your PDFs in S3 with this structure:
```
grade_7/
  mathematics/
    chapter1.pdf
    chapter2.pdf
  science/
    chapter1.pdf
grade_8/
  mathematics/
    chapter1.pdf
```

### 6. Usage Examples

#### In Views
```erb
<!-- List PDFs by grade -->
<% pdfs = S3PdfService.list_pdfs_by_grade(7) %>
<% pdfs.each do |pdf_key| %>
  <%= link_to File.basename(pdf_key), S3PdfService.get_pdf_url(pdf_key), target: "_blank" %>
<% end %>

<!-- Using helpers -->
<%= link_to "View PDF", s3_signed_url("grade_7/mathematics/chapter1.pdf"), target: "_blank" %>
```

#### In Controllers
```ruby
def index
  @pdfs = S3PdfService.list_pdfs_by_grade(params[:grade])
end
```

## Troubleshooting

### Common Issues

1. **403 Access Denied**: Check IAM permissions and bucket policy
2. **Signature Mismatch**: Ensure region matches bucket region
3. **PDFs not loading**: Check CORS configuration and bucket permissions

### Testing Commands

```bash
# Test S3 connectivity
rails console
> S3_CLIENT.list_buckets

# Test PDF listing
> S3PdfService.list_pdfs_by_grade(7)

# Test URL generation
> S3PdfService.get_pdf_url("grade_7/mathematics/chapter1.pdf")
```

## Security Notes

- Keep AWS credentials secure
- Use IAM roles with minimal required permissions
- Consider using presigned URLs for private access
- Monitor S3 access logs for security

## Migration from Local Storage

If you have existing PDFs in local storage:
1. Upload them to S3 using the organized structure
2. Update any hardcoded PDF paths
3. Test thoroughly before deploying to production

## Support

For issues or questions, check:
- AWS S3 documentation
- Rails Active Storage documentation
- Your AWS CloudTrail logs for access issues
