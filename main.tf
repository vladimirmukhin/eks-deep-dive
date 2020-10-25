terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "vlad.terraform"
    key            = "tfstate/"
    region         = "us-east-1"
    dynamodb_table = "terraform"
  }
}

provider "aws" {
  region = "us-east-1"
}
