variable "instance_type" {
  description = "Free tier instance type"
  type        = string
  default     = "t3.small"
}
variable "key_name" {
  description = "Using the AWS key pair linked to the aws-project directory for the EC2 instances"
  type        = string
  default     = "aws_homelab"
}
