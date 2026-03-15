# Shared runtime infrastructure in the automation account.
# DynamoDB tables, SNS topics, SQS queues, Sweeper ECS task,
# trigger Lambda, CodeArtifact, cross-account role.

variable "workload_ou_arn" {
  description = "ARN of the workload OU for cross-account trust."
  type        = string
}

variable "sweeper_image" {
  description = "ECR image URI for the Sweeper ECS task."
  type        = string
  default     = ""
}

locals {
  tags = {
    Project   = "detent"
    ManagedBy = "terraform"
  }
}
