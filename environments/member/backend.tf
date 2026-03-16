terraform {
  backend "s3" {
    key     = "member/terraform.tfstate"
    encrypt = true
  }
}
