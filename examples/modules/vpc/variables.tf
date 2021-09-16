
variable "prefix" {
  description = "Virtual Private Network prefix"
  type = string
}

variable "environment" {
  description = "The name of the environment"
  type = string
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  type = string
}

variable "public_subnets" {
  description = "List of public subnets"
  type = list(string)
}

variable "private_subnets" {
  description = "List of private subnets"
  type = list(string)
}

