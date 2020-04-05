provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Owner = "aws-ipv6-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                          = "${aws_vpc.main.id}"
  cidr_block                      = "10.0.0.0/24"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)}"
  availability_zone               = "${var.aws_region}c"
  # set the default to true for public IPv4 assocations
  map_public_ip_on_launch         = true
  # set the default to true for public IPv6 assocations
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "aws-ipv6-subnet"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.main.id}"
  tags   = {
    Name  = "aws-ipv6-igw"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main"
  }
}

resource "aws_route" "ipv4_route" {
  route_table_id            = "${aws_route_table.route_table.id}"
  gateway_id                = "${aws_internet_gateway.gateway.id}"
  destination_cidr_block    = "0.0.0.0/0"
}

resource "aws_route" "ipv6_route" {
  route_table_id              = "${aws_route_table.route_table.id}"
  gateway_id                = "${aws_internet_gateway.gateway.id}"
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_route_table_association" "subnet_to_route_table" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.route_table.id}"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "sg" {
  name        = "aws-ipv6-sg"
  description = "aws-ipv6-sg"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "allow all ipv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow all ipv6"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "allow all ipv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all ipv6"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "aws-ipv6-sg"
  }
}

resource "aws_instance" "i" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.main.id}"
  associate_public_ip_address = true
  ipv6_address_count          = 1
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  key_name                    = "${var.ec2_keypair}"

  tags = {
    Name = "aws-ipv6-instance"
  }
}
