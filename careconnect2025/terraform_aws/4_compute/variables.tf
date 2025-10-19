variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Purpose    = "capstone at UMGC"
    CourseCode = "SWEN-670"
    Project    = "careconnect"
    Use        = "IaC"
  }
}
variable "cc_iac_bucket_name" {
  description = "S3 bucket name where application packages are stored"
  type        = string
}

variable "cc_main_backend_package_zip_s3key" {
  description = "Full S3 key for the main backend package zip file"
  type        = string
}

variable "cc_main_frontend_package_zip_s3key" {
  description = "Full S3 key for the main web app zip file"
  type        = string
}


variable "cc_main_compute_env_vars" {
  description = "Environment variables for the main Lambda function"
  type        = map(string)
  default = {}
}
variable "cors_allowed_list" {
  description = "List of allowed CORS origins"
  type        = string
  default     = "http://localhost:*,http://127.0.0.1:*"
}
variable "cc_main_backend_build_prefix" {
  description = "Prefix for the main backend build files in S3"
  type        = string
  default     = "cc-backend-builds/"
}

variable "cc_main_frontend_build_prefix" {
  description = "Prefix for the main backend build files in S3"
  type        = string
  default     = "cc-frontend-builds/"
}

variable "absolute_path_to_backend_artifact" {
  description = "Absolute path to backend artifact (zip file)"
  type = string
}

variable "absolute_path_to_frontend_webapp" {
  description = "Absolute path to frontend artifact (web folder)"
  type = string
}
