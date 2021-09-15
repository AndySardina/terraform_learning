variable "prefix" {
  description = "Virtual Private Network prefix"
  type = string
}

variable "environment" {
  description = "The name of your environment"
  type = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type = string
}

variable "subnets" {
  description = "Comma separated list of subnet IDs"
}

variable "alb_security_groups" {
  description = "Comma separated list of security groups"
}

variable "health_check_path" {
  description = "Path to check if the service is healthy, e.g. \"/status\""
  type = string
}
