variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "workload_ou_id" {
  description = "ID of the workload OU to attach the SCP to."
  type        = string
}
