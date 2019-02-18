locals {
  my_name = "${var.prefix}-${var.env}-ec2"
  my_env = "${var.prefix}-${var.env}"
  ubuntu18_ami = "ami-00035f41c82244dab"
  my_private_key = "vm_id_rsa"
}

//
//resource "tls_private_key" "ssh-key" {
//  algorithm   = "RSA"
//}
//
//# NOTE: If you get 'No available provider "null" plugins'
//# Try: terraform init, terraform get, terraform plan.
//# I.e. resource occasionally fails the first time.
//# When the resource is succesfull you should see the private key
//# in ./terraform/modules/vm/.ssh folder.
//resource "null_resource" "save-ssh-key" {
//  triggers {
//    key = "${tls_private_key.ssh-key.private_key_pem}"
//  }
//
//  # I realized later that this works only when you are able to use some unix like shell.
//  # Probably better to provide another version in which one can create the key
//  # manually and the infra code injects that key to the vm.
//  # NOTE: We cannot use path.module with Git Bash since it fails with path.
//  # Use these lines instead with Git Bash:
//  #    mkdir .ssh
//  #    echo "${tls_private_key.ssh-key.private_key_pem}" > .ssh/${local.my_private_key}
//  provisioner "local-exec" {
//    command = <<EOF
//      mkdir -p ${path.module}/.ssh
//      echo "${tls_private_key.ssh-key.private_key_pem}" > ${path.module}/.ssh/${local.my_private_key}
//      chmod 0600 ${path.module}/.ssh/${local.my_private_key}
//EOF
//  }
//}
//
//resource "aws_key_pair" "app_ec2_key_pair" {
//  key_name   = "${local.my_name}-key-pair"
//  public_key = "${tls_private_key.ssh-key.public_key_pem}"
//}



resource "aws_iam_instance_profile" "app_ec2_iam_profile" {
  name = "${local.my_name}-iam-profile"
  role = "${aws_iam_role.app_ec2_role.name}"
}

resource "aws_iam_role" "app_ec2_role" {
  name = "${local.my_name}-iam-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags {
    Name        = "${local.my_name}-iam-role"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}


resource "aws_eip" "app_ec2_eip" {
  instance = "${aws_instance.app_ec2.id}"
  vpc      = true

  tags {
    Name        = "${local.my_name}-eip"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}


resource "aws_instance" "app_ec2" {
  ami                    = "${local.ubuntu18_ami}"
  instance_type          = "t2.micro"
  subnet_id              = "${var.app_subnet_id}"
  vpc_security_group_ids = ["${var.app_subnet_sg_id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.app_ec2_iam_profile.name}"

  tags {
    Name        = "${local.my_name}"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}
