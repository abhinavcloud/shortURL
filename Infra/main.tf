
provider "aws" {
  profile = "default"

}

module "Storage" {
  source          = "./Storage/"
}