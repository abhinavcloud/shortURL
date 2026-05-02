variable "bucket_name" {
  description = "S3 bucket name for the website"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "bucket_regional_domain_name" {
    description = "Regional domain name"
    type = string
}

variable "base_url" {
    description = "Base URL for API Gateway stage."
    type = string
}