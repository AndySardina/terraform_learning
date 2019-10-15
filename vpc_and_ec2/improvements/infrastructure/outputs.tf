output "vpc_id" {
  value = aws_vpc.production-vpc.id
}

output "vpc_cider_block" {
  value = aws_vpc.production-vpc.cidr_block
}

output "public_subnets_id" {
   value = [ for subnet in aws_subnet.public_subnets: subnet.id ]
}

output "private_subnets_id" {
  value = [ for subnet in aws_subnet.private_subnets: subnet.id ]
}
