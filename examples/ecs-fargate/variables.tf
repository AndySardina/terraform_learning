variable "region" {
  description = "Region in which the infrastructure will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "prefix" {
  description = "Virtual Private Network prefix"
  type        = string
  default     = "andsar"
}

variable "environment" {
  description = "The name of the environment"
  type        = string
  default     = "test"
}


variable "cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnets"
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.20.0/24", "10.30.30.0/24"]
}

variable "private_subnets" {
  description = "List of private subnets"
  type        = list(string)
  default     = ["10.30.50.0/24", "10.30.60.0/24", "10.30.70.0/24"]
}

variable "service_desired_count" {
  description = "Number of tasks running in parallel"
  type = number
  default     = 2
}

variable "container_port" {
  description = "Ingres and egress port of the container"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "The number of cpu units used by the task"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "The amount (in MiB) of memory used by the task"
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "Http path for task health check"
  type        = string
  default     = "/health"
}
