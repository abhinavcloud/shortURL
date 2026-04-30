variable "dynamodb_table_arn" {
    type = string
    description = "ARN of the DynamoDB table"
}

variable "dynamodb_table_name" {
    type = string
    description = "Dynamo DB Table Name"
}

variable "cloudfront_domain_name" {
    type = string
    description = "CloudFront Domain Name"
}