
output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "vpc_arn" {
  value = "${aws_vpc.vpc.arn}"
}

output "app_subnet_id" {
  value = "${aws_subnet.app-subnet.id}"
}

