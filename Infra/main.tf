
provider "aws" {
}

provider "archive" {
  
}


module "Storage" {
  source          = "./Storage/"
}

module "Cloudfront" {
  source = "./Cloudfront/"

  bucket_name                    = module.Storage.bucket_name
  bucket_arn                     = module.Storage.bucket_arn
  bucket_regional_domain_name    = module.Storage.bucket_regional_domain_name

}