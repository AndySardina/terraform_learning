provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
}

resource "aws_vpc" "production-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "Production VPC"
  }
}

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets_definition

  vpc_id = aws_vpc.production-vpc.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.production-vpc.cidr_block, 8, each.value)

  tags = {
    // The regex returns a list, that's why I am only taking the first element
    Name = format("public-subnet-%s",  regex("\\w+-\\w+-(\\d\\w)", each.key)[0] )
    Type = "public"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets_definition

  vpc_id = aws_vpc.production-vpc.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.production-vpc.cidr_block, 8, each.value)

  tags = {
    // The regex returns a list, that's why I am only taking the first element
    Name = format("private-subnet-%s",  regex("\\w+-\\w+-(\\d\\w)", each.key)[0] )
    Type = "private"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "public-subnets-assosiation" {
  for_each = var.public_subnets_definition

  route_table_id = aws_route_table.public-route-table.id
  subnet_id = aws_subnet.public_subnets[each.key].id
}

resource "aws_route_table_association" "private-subnets-assosiation" {
  for_each = var.private_subnets_definition

  route_table_id = aws_route_table.private-route-table.id
  subnet_id = aws_subnet.private_subnets[each.key].id
}

resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"

  tags = {
    Name = "Production EIP"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  // The NAT Gateway will live in the first public subnet defined in the map for public subnets.
  subnet_id     = aws_subnet.public_subnets[ keys(aws_subnet.public_subnets)[0] ].id

  tags = {
    Name = "Production NAT Gateway"
  }

  depends_on = [aws_eip.elastic-ip-for-nat-gw]
}

resource "aws_route" "nat-gw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.production-vpc.id

  tags = {
    Name = "Production Internet Gateway"
  }
}

resource "aws_route" "public-internet-gw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.production-igw.id
  destination_cidr_block = "0.0.0.0/0"
}

