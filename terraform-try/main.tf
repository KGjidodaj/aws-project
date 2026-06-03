terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0" #limiting to major 6.x releases
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}
