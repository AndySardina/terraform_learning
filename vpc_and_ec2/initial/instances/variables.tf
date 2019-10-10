variable "region" {
  default = "eu-west-1"
  description = "AWS Region"
}

variable "remote_state_bucket" {
  description = "Bucket name for layer 1 remote state."
}

variable "remote_state_key" {
  description = "Key name for layer 1 remote state."
}

variable "ec2_instance_type" {
  description = "EC2 Instance type to launch."
}

variable "key_pair_name" {
  default     = "DevKeyPair"
  description = "Key pair to use to connect to EC2 Instances."
}

variable "max_instance_size" {
  description = "maximun number of instances to launch."
}

variable "min_instance_size" {
  description = "Minimun number of instances to launch."
}
