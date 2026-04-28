
provider "aws" {
  profile = "default"

}

module "Storage" {
  source          = "../Storage/"
  common_tags     = local.common_tags
  vpc_endpoint_id = module.Network.vpc_endpoint_id
  depends_on      = [module.Security_Groups]
}