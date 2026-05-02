variable "create_function_name" {
type = string
description = "Lambda Function Name"

}

variable "get_function_name" {
    type = string  
    description = "Lambda Function Name for GET /{shortUrlId}"

}

variable "create_integration_uri" {
    type = string
    description = "Lambda interation uri"
}

variable "get_integration_uri" {
    type = string
    description = "Lambda interation uri for GET /{shortUrlId}"
}


variable "region" {
    type = string
    description = "Region Name"
}

variable "cognito_user_pool_id" {
    type = string
    description = "Cognito User Pool Id"
}

variable "cognito_client_id" {
    type = string
    description = "Congnito User Pool Client Id"
}


variable "allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
}
