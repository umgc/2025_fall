# backend.tf

terraform {
  backend "s3" {
    # Replace with your S3 bucket name
    key    = "careconnect-db-aurora-pg/terraform.tfstate" 
    region = "us-east-1"

    # Enable state locking and consistency
    # dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}