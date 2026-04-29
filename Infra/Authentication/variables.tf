variable "client_id" {
    type = string
    description = "Google OAuth Client Id"
}

variable "client_secret" {
    type = string
    description = "Google OAuth Client Secret"
}

variable "cloudfront_domain_name" {
    type = string
    description = "Cloudfront domain name"
}

variable "app_name" {
    type = string
    description = "Application name"
}

variable "env" {
    type = string
    description = "Environment name"
}