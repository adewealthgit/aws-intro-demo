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

resource "aws_security_group" "app-subnet-sg" {
  name        = "${local.my_name}-app-subnet-sg"
  description = "For testing purposes, create ingress rules manually"
  vpc_id      = "${aws_vpc.vpc.id}"


  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
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


