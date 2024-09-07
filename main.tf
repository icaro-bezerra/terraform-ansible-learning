terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.66.0"
    }
  }
}

provider "aws" {
  region  = "sa-east-1"
  profile = "default"
}

# VPC

resource "aws_vpc" "vpc_simple" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "simple-vpc"
  }
}

# Subnet

resource "aws_subnet" "subnet_public" {
  vpc_id            = aws_vpc.vpc_simple.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "sa-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_simple.id
  tags = {
    Name = "internet-gateway"
  }
}

# Route Table

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc_simple.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Route Table Association

resource "aws_route_table_association" "rta_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_public.id
}

# Security Group

resource "aws_security_group" "sg_web" {
  vpc_id = aws_vpc.vpc_simple.id
  ingress {
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
    Name = "web-sg"
  }
}

# EC2 Instance

resource "aws_instance" "web_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_public.id
  security_groups = [aws_security_group.sg_web.name]
  tags = {
    Name = "web-instance"
  }
}

# Output

output "instance_public_ip" {
  description = "The public IP address of the web instance"
  value       = aws_instance.web_instance.public_ip
}