variable "region" {
  description = "Region in which the infrastructure will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "public_subnet_count" {
  description = "Amount of public subnets to use"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Amount of private subnets to use"
  type        = number
  default     = 2
}


