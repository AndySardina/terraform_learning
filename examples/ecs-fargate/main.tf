terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 1.0.6"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source          = "../modules/vpc"
  prefix           = var.prefix
  cidr            = var.cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  environment     = var.environment
}

module "security_groups" {
  source         = "../modules/security-groups"
  prefix          = var.prefix
  vpc_id         = module.vpc.id
  environment    = var.environment
  container_port = var.container_port
}

module "alb" {
  source      = "../modules/alb"
  prefix       = var.prefix
  vpc_id      = module.vpc.id
  subnets     = module.vpc.public_subnets
  environment = var.environment
  alb_security_groups = [module.security_groups.alb]
  health_check_path = var.health_check_path
}

module "ecr" {
  source      = "../modules/ecr"
  prefix       = var.prefix
  environment = var.environment
}

module "ecs" {
  source                      = "../modules/ecs"
  prefix                       = var.prefix
  environment                 = var.environment
  region                      = var.region
  subnets                     = module.vpc.private_subnets
  aws_alb_target_group_arn    = module.alb.aws_alb_target_group_arn
  ecs_service_security_groups = [module.security_groups.ecs_tasks]
  container_port              = var.container_port
  container_cpu               = var.container_cpu
  container_memory            = var.container_memory
  container_image             = "nginxdemos/nginx-hello"
  service_desired_count       = var.service_desired_count
  container_environment = [
    { name = "LOG_LEVEL",  value = "DEBUG" },
    { name = "PORT",       value = tostring(var.container_port) }
  ]
}
