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

  # Run with credentials that have Organizations access in the
  # management account (e.g. AWS_PROFILE=mgmt-admin).

  default_tags {
    tags = {
      Project     = "Research and Development"
      ManagedBy   = "terraform"
      Environment = "management"
    }
  }
}
