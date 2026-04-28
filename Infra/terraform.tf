#Created by: Abhinav Kumar (abhinav@abhinav-cloud.com)
#Version 1.0

terraform {
  required_version = ">= 1.13.0"


  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "6.42.0"
    }

  }
}