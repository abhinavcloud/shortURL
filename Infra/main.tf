
provider "aws" {
}

provider "archive" {

}

data "aws_region" "current" {}


module "Storage" {
  source = "./Storage/"
}

module "Cloudfront" {
  source = "./Cloudfront/"

  bucket_name                 = module.Storage.bucket_name
  bucket_arn                  = module.Storage.bucket_arn
  bucket_regional_domain_name = module.Storage.bucket_regional_domain_name
  base_url                    = module.APIGateway.base_url

}

module "Authentication" {
  source = "./Authentication"

  client_id     = var.client_id
  client_secret = var.client_secret

  cloudfront_domain_name = module.Cloudfront.cloudfront_domain_name

  app_name = var.app_name
  env      = var.env

}

module "DynamoDB" {
  source = "./DynamoDB"
}

module "Compute" {
  source = "./Compute"

  dynamodb_table_arn = module.DynamoDB.dynamodb_table_arn

  dynamodb_table_name = module.DynamoDB.dynamodb_table_name

  cloudfront_domain_name = module.Cloudfront.cloudfront_domain_name


}

module "APIGateway" {

  source = "./APIGateway"

  create_function_name = module.Compute.create_function_name

  get_function_name = module.Compute.get_function_name


  create_integration_uri = module.Compute.create_integration_uri

  get_integration_uri = module.Compute.get_integration_uri

  allowed_origins = [
    "http://localhost:3000",
    "https://go.abhinav-cloud.com"
  ]
  
  cognito_user_pool_id = module.Authentication.cognito_user_pool_id

  region = data.aws_region.current.region

  cognito_client_id = module.Authentication.cognito_client_id


}


