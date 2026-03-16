# Jenkins platform on ECS.
# Controller runs on EC2 (long-lived, stateful).
# Agents and Sweeper run on Fargate (ephemeral, burst).

variable "vpc_id" {
  description = "VPC ID for all Jenkins resources."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for controller, agents, and EFS."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB."
  type        = string
}

variable "jenkins_image" {
  description = "ECR image URI for the Jenkins controller."
  type        = string
}

variable "agent_image" {
  description = "ECR image URI for the Jenkins agent."
  type        = string
}

variable "domain_name" {
  description = "Domain name for Jenkins (e.g. jenkins.detent.example.com)."
  type        = string
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password."
  type        = string
  sensitive   = true
}

variable "controller_instance_type" {
  description = "EC2 instance type for the Jenkins controller."
  type        = string
  default     = "t3.medium"
}

variable "controller_key_name" {
  description = "EC2 key pair name for SSH access to the controller instance."
  type        = string
  default     = ""
}

variable "agent_cpu" {
  description = "CPU units for Jenkins agents."
  type        = number
  default     = 256
}

variable "agent_memory" {
  description = "Memory (MiB) for Jenkins agents."
  type        = number
  default     = 512
}

variable "automation_role_arn" {
  description = "ARN of AutomationFrameworkAccess role agents can assume."
  type        = string
  default     = ""
}

locals {
  tags = {
    Project   = "Research and Development"
    System    = "detent"
    ManagedBy = "terraform"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
