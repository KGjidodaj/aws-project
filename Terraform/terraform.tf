# Setting up the configuration of terraform and provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" #limiting to major 6.x releases
    }
  }
  required_version = ">= 1.15"
  # Using s3 bucket as backend
  backend "s3" {
    bucket = "aws-project-kris-2026"
    key    = "aws-project/terraform.tfstate"
    region = "eu-north-1"
  }


}

provider "aws" {
  region = "eu-north-1"
}
