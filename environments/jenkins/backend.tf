terraform {
  backend "s3" {
    key     = "jenkins/terraform.tfstate"
    encrypt = true
  }
}
