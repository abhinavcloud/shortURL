variable "function_name" {
type = string
description = "Lambda Function Name"

}

variable "integration_uri" {
    type = string
    description = "Lambda interation uri"
}

variable "cloudfront_domain_name" {
    type = string
    description = "CloudFront Domain Name"
}