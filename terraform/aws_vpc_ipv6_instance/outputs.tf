
output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "vpc_ipv6_cidr" {
  value = "${aws_vpc.main.ipv6_cidr_block}"
}

output "internet_gateway_id" {
  value = "${aws_internet_gateway.gateway.id}"
}

output "route_table_id" {
  value = "${aws_route_table.route_table.id}"
}

output "subnet_id" {
  value = "${aws_subnet.main.id}"
}

output "subnet_ipv6_cidr" {
  # Keep this in sync with ipv6_cidr_block arg to aws_subnet
  value = "${"${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)}"}"
}

output "security_group_id" {
  value = "${aws_security_group.sg.id}"
}

output "instance_id" {
  value = "${aws_instance.i.id}"
}

output "instance_public_ipv4" {
  value = "${aws_instance.i.public_ip}"
}

output "instance_ipv6_addresses" {
  value = "${aws_instance.i.ipv6_addresses}"
}

