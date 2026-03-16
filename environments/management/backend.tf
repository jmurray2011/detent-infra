terraform {
  backend "s3" {
    # Configured at init time via -backend-config=backend.hcl
    # Required keys: bucket, region, dynamodb_table
    key     = "management/terraform.tfstate"
    encrypt = true
  }
}
