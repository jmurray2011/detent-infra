terraform {
  backend "s3" {
    key     = "automation/terraform.tfstate"
    encrypt = true
  }
}
