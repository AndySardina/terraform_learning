variable "region" {
  default     = "eu-west-1"
  description = "AWS Region"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "VPC CIDR Block"
}

variable "public_subnets_definition" {
  description = "Map from availability zone to the number that should be used for each availability zone's subnet"

  default     = {
    "eu-west-1a" = 1
  }
}

