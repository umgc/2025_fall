output "backend_bucket_name" {
  description = "The name of the S3 bucket used for Terraform backend state."
  value       = aws_s3_bucket.backend_bucket.bucket
}
