terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.15.1"
}

provider "aws" {
  region = var.region
}


#################################################################################
#   Network Definition 
#################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "paf" {
  name         = "playground.pafcloud.net"
  private_zone = false
}
#################################################################################



#################################################################################
#   Network Definition 
#################################################################################

# VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.30.0.0/16"
  instance_tenancy = "default"
}


# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.30.30.0/24"

  tags = {
    Name = "andsar-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[2]
  cidr_block        = "10.30.40.0/24"

  tags = {
    Name = "andsar-public-subnet-2"
  }
}

# Internet Gateway and Route Table
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "andsar-igw-1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "andsar-route-table-1"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.30.50.0/24"

  tags = {
    Name = "andsar-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[2]
  cidr_block        = "10.30.60.0/24"

  tags = {
    Name = "andsar-private-subnet-2"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_2.id

  tags = {
    Name = "andsar-nat-gw-1"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "andsar-route-table-2"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
#################################################################################




#################################################################################
# Compute Definition
#################################################################################

# Security Groups
resource "aws_security_group" "allow_public_http" {
  name        = "andsar-sg-1"
  description = "Allow HTTP inbound traffic from the Internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "andsar-sg-1"
  }
}

resource "aws_security_group" "internal_http" {
  name        = "andsar-sg-2"
  description = "Allows HTTP traffic from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_public_http.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "andsar-sg-2"
  }

}

# AWS Launch Template
resource "aws_launch_template" "sample_app" {
  name = "sample-app-launch-template"

  image_id = data.aws_ami.ami.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.internal_http.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "apache-server"
    }
  }

  user_data = filebase64("${path.module}/scripts/init.sh")
}

resource "aws_lb_target_group" "webserver" {
  name     = "andsar-target-group-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
  }
}

resource "aws_lb" "alb" {
  name               = "andsar-alb-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_public_http.id]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }

}

resource "aws_autoscaling_group" "asg" {
  name             = "andsar-ag-1"
  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  vpc_zone_identifier = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  launch_template {
    id      = aws_launch_template.sample_app.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.webserver.arn]
  health_check_grace_period = 300
}

# DNS Record 

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.paf.zone_id
  name    = "andsar.playground.pafcloud.net"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

#################################################################################

