locals {
  my_name = "${var.prefix}-${var.env}-vpc"
  my_env = "${var.prefix}-${var.env}"
}


data "aws_availability_zones" "available" {}



resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"

  tags {
    Name        = "${local.my_name}"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}


# Eip needs Internet gateway.
resource "aws_internet_gateway" "app_ec2_internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${local.my_name}-ig"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}


resource "aws_subnet" "app-subnet" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.app_subnet_cidr_block}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name        = "${local.my_name}-app-subnet"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}


# To make a public subnet we need to route its traffic to internet gateway.
resource "aws_route_table" "app_subnet_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.app_ec2_internet_gateway.id}"
  }

  tags {
    Name        = "${local.my_name}-app-subnet-route-table"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}


resource "aws_route_table_association" "app_subnet_route_table_association" {
  subnet_id      = "${aws_subnet.app-subnet.id}"
  route_table_id = "${aws_route_table.app_subnet_route_table.id}"
}


resource "aws_security_group" "app-subnet-sg" {
  name        = "${local.my_name}-app-subnet-sg"
  description = "For testing purposes, create ingress rules manually"
  vpc_id      = "${aws_vpc.vpc.id}"

  // Open port 22 (ssh) to test logging into the EC2 instance using your ssh key.
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Terraform removes the default rule.
  // Let's comment this now since terraform wants to change the sg in every apply.
  // See: https://github.com/hashicorp/terraform/issues/9602
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${local.my_name}-app-subnet-sg"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}


