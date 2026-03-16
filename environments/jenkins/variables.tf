variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# --- Network ---

variable "cidr_block" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to use (at least 2 for ALB)."
  type        = list(string)
}

variable "domain_name" {
  description = "Domain for this environment (e.g. detent.example.com)."
  type        = string
}

# --- Jenkins ---

variable "jenkins_image" {
  description = "ECR image URI for the Jenkins controller."
  type        = string
}

variable "agent_image" {
  description = "ECR image URI for the Jenkins agent."
  type        = string
}

variable "jenkins_admin_password_secret_arn" {
  description = "Secrets Manager ARN for the Jenkins admin password."
  type        = string
}

variable "automation_role_arn" {
  description = "ARN of AutomationFrameworkAccess role agents can assume."
  type        = string
  default     = ""
}
