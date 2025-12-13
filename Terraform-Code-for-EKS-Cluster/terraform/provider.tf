terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70" # FIX
    }
  }

  backend "s3" {
    bucket         = "bms-tf-state-bucket"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "bms-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

