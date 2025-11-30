terraform {
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

locals {
  region          = "ap-south-1"
  name            = "bms-cluster"
  vpc_cidr        = "10.123.0.0/16"
  azs             = ["ap-south-1a", "ap-south-1b"]
  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
  intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]
  tags = {
    Example = local.name
  }
}
