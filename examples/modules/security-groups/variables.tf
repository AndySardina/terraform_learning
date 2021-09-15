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

variable "container_port" {
  description = "Ingres and egress port of the container"
  type = number
}
