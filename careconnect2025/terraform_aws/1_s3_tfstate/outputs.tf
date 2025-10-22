output "backend_bucket_name" {
  description = "The name of the S3 bucket used for Terraform backend state"
  value       = aws_s3_bucket.backend_bucket.id
}

output "backend_bucket_arn" {
  description = "The ARN of the S3 bucket used for Terraform backend state"
  value       = aws_s3_bucket.backend_bucket.arn
}

output "backend_bucket_region" {
  description = "The region of the S3 bucket"
  value       = aws_s3_bucket.backend_bucket.region
}