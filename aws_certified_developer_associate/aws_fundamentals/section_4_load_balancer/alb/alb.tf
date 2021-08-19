provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "network_configuration" {
  backend = "s3"
  config  = {
    bucket = var.remote_state_bucket
    key    = var.remote_state_key
    region = var.region
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  name        = "ALB-SG"
  description = "Internet reaching acces for the ALB."
  vpc_id       = data.terraform_remote_state.network_configuration.outputs.vpc_id

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_security_group" {
  name        = "EC2-Public-SG"
  description = "Internet reaching acces for EC2 Instances."
  vpc_id       = data.terraform_remote_state.network_configuration.outputs.vpc_id

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_public" {
  ami                         = "ami-0ce71448843cb18a1"
  instance_type               = var.ec2_instance_type
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  subnet_id                   = data.terraform_remote_state.network_configuration.outputs.public_subnets_id[0]
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]

  user_data = <<EOF
#!/bin/bash

yum update -y
yum install httpd.x86_64 -y
systemctl start httpd.service
systemctl enable httpd.service
chkconfig httpd on

export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
echo "<html><body><h1>Hello from Production Backend at instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html

EOF
}

resource "aws_lb" "load_balancer" {
  name               = "Public-Load-Balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = data.terraform_remote_state.network_configuration.outputs.public_subnets_id

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }

}

resource "aws_lb_target_group" "front-end-instances" {
  name     = "apache-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network_configuration.outputs.vpc_id

  health_check {
    protocol = "HTTP"
    path     = "/"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front-end-instances.arn
  }
}

resource "aws_lb_target_group_attachment" "lb_attachment" {
  target_group_arn = aws_lb_target_group.front-end-instances.arn
  target_id        = aws_instance.ec2_public.id
}

