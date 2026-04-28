
provider "aws" {


}

module "Storage" {
  source          = "./Storage/"
}