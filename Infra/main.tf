
provider "aws" {
}

provider "archive" {
  
}


module "Storage" {
  source          = "./Storage/"
}