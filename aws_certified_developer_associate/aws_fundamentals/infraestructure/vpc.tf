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

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public-subnets-assosiation" {
  for_each = var.public_subnets_definition

  route_table_id = aws_route_table.public-route-table.id
  subnet_id = aws_subnet.public_subnets[each.key].id
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

