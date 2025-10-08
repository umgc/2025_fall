module "internal_storage" {
  source = "./modules/s3"

  bucket_name         = var.s3.bucket_name
  versioning_enabled  = true
  sse_algorithm       = "AES256"
  block_public_access = true

  lifecycle_rules = var.s3.lifecycle_rules
  cors_rules      = var.s3.cors_rules

  tags = local.default_tags
}
