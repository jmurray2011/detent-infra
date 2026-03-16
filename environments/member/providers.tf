terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = var.target_account_role_arn
  }

  default_tags {
    tags = {
      Project     = "Research and Development"
      ManagedBy   = "terraform"
      Environment = "member"
    }
  }
}
