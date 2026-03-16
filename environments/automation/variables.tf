variable "aws_region" {
  type    = string
  default = "us-east-1"
}

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
  description = "ARN of the existing ECS cluster."
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

variable "jenkins_url" {
  description = "Jenkins base URL."
  type        = string
  default     = "http://jenkins:8080"
}

variable "jenkins_user" {
  description = "Jenkins API user."
  type        = string
  default     = "admin"
}

variable "jenkins_token" {
  description = "Jenkins API token."
  type        = string
  sensitive   = true
}

variable "job_routes" {
  description = "JSON map of job_type to Jenkins job path."
  type        = string
  default     = "{}"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alert notifications."
  type        = string
  default     = ""
  sensitive   = true
}

variable "alert_email_addresses" {
  description = "Email addresses to subscribe to ops-alerts."
  type        = list(string)
  default     = []
}
