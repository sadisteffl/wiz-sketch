variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "security_alert_email" {
  description = "The email address to send critical security alerts to."
  type        = string
  default     = "sadisteffl@gmail.com"
}

variable "instance_type" {
  description = "The EC2 instance type for the database VM."
  type        = string
  default     = "t3.micro"
}

variable "db_user" {
  description = "The username for the application database user."
  type        = string
  default     = "taskyapp"
}


variable "alert_email" {
  description = "Email to receive CloudTrail alerts"
  type        = string
}
