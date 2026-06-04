terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" #limiting to major 6.x releases
    }
  }
  required_version = ">= 1.15"
}

provider "aws" {
  region = "eu-north-1"
}
