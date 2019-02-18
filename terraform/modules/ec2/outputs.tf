

output "ec2_eip" {
  value = "${aws_eip.app_ec2_eip.public_ip}"
}

