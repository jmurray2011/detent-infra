# Shared runtime infrastructure in the automation account.
# DynamoDB tables, SNS topics, SQS queues, Sweeper ECS task,
# trigger Lambda, CodeArtifact, cross-account role.

variable "workload_ou_arn" {
  description = "ARN of the workload OU for cross-account trust."
  type        = string
}

variable "workload_ou_id" {
  description = "ID of the workload OU (e.g. ou-xxxx-xxxxxxxx)."
  type        = string
}

variable "org_id" {
  description = "AWS Organizations ID (e.g. o-xxxxxxxxxx)."
  type        = string
}

variable "sweeper_image" {
  description = "ECR image URI for the Sweeper ECS task."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ARN of the existing ECS cluster for the Sweeper task."
  type        = string
}

variable "sweeper_subnet_ids" {
  description = "Subnet IDs for the Sweeper Fargate task."
  type        = list(string)
}

variable "sweeper_security_group_ids" {
  description = "Security group IDs for the Sweeper Fargate task."
  type        = list(string)
}

locals {
  tags = {
    Project   = "Research and Development"
    System    = "detent"
    ManagedBy = "terraform"
  }
}
