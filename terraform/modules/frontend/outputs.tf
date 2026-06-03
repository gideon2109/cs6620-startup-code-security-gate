output "bucket_name" {
  description = "The name of the frontend S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "website_url" {
  description = "The website URL of the frontend"
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}
