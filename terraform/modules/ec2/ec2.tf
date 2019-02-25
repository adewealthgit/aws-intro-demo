locals {
  my_name = "${var.prefix}-${var.env}-ec2"
  my_env = "${var.prefix}-${var.env}"
  ubuntu18_ami = "ami-00035f41c82244dab"
  my_private_key = "vm_id_rsa"
}


# NOTE: You need to "terraform init" to get the tls provider!
resource "tls_private_key" "app_ec2_ssh_key" {
  algorithm   = "RSA"
}

# NOTE: If you get 'No available provider "null" plugins'
# Try: terraform init, terraform get, terraform plan.
# I.e. resource occasionally fails the first time.
# When the resource is succesfull you should see the private key
# in ./terraform/modules/vm/.ssh folder.

# We have two versions since the private ssh key needs to be stored in the local
# workstation differently in Linux and Windows workstations.

# First the Linux version (my_workstation_is_linux = 1)
resource "null_resource" "app_ec2_save_ssh_key_linux" {
  count = "${var.my_workstation_is_linux}"
  triggers {
    key = "${tls_private_key.app_ec2_ssh_key.private_key_pem}"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.app_ec2_ssh_key.private_key_pem}" > ${path.module}/.ssh/${local.my_private_key}
      chmod 0600 ${path.module}/.ssh/${local.my_private_key}
EOF
  }
}


# Then the Windows version (my_workstation_is_linux = 0)
# Solution to store the file in Windows with UTF-8 encoding
# and fixing the access rights for the file kindly provided by Sami Huhtiniemi.
resource "null_resource" "app_ec2_save_ssh_key_windows" {
  count = "${1 - var.my_workstation_is_linux}"
  triggers {
    key = "${tls_private_key.app_ec2_ssh_key.private_key_pem}"
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell"]
    command = <<EOF
      md ${path.module}\\.ssh
      [IO.File]::WriteAllLines(("${path.module}\.ssh\${local.my_private_key}"), "${tls_private_key.vm_ssh_key.private_key_pem}")
      icacls ${path.module}\.ssh\${local.my_private_key} /reset
      icacls ${path.module}\.ssh\${local.my_private_key} /grant:r "$($env:USERNAME):(R,W)"
      icacls ${path.module}\.ssh\${local.my_private_key} /inheritance:r
EOF
  }
}


resource "aws_key_pair" "app_ec2_key_pair" {
  key_name   = "${local.my_name}-key-pair"
  public_key = "${tls_private_key.app_ec2_ssh_key.public_key_openssh}"
}



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
  key_name = "${aws_key_pair.app_ec2_key_pair.key_name}"

  tags {
    Name        = "${local.my_name}"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}

