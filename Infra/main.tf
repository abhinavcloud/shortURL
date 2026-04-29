
provider "aws" {
}

provider "archive" {

}


module "Storage" {
  source = "./Storage/"
}

module "Cloudfront" {
  source = "./Cloudfront/"

  bucket_name                 = module.Storage.bucket_name
  bucket_arn                  = module.Storage.bucket_arn
  bucket_regional_domain_name = module.Storage.bucket_regional_domain_name

}

module "Authentication" {
  source = "./Authentication"

  client_id     = var.client_id
  client_secret = var.client_secret

  cloudfront_domain_name = module.Cloudfront.cloudfront_domain_name

  app_name = var.app_name
  env      = var.env

}
