output "ec2_instance_ip" {
  value = aws_instance.ec2_public.public_ip
}

