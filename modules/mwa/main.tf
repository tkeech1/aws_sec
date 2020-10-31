resource "aws_vpc" "mwa_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    environment = var.environment
  }
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.mwa_vpc.default_network_acl_id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "108.16.31.89/32"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "18.206.107.24/29"
    from_port  = 22
    to_port    = 22
  }

  # allow https return traffic from https://inspector-agent.amazonaws.com/linux/latest/install
  # https://s3.dualstack.us-east-1.amazonaws.com/aws-agent.us-east-1/linux/latest/inspector.gpg
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 32768
    to_port    = 65535
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_default_security_group" "mwa_security_group" {
  vpc_id = aws_vpc.mwa_vpc.id

  ingress {
    description = "SSH from Local and EC2 Instance Connect"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["108.16.31.89/32", "18.206.107.24/29"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["108.16.31.89/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}

// Create subnets in different AZs
resource "aws_subnet" "public_subnet_one" {
  vpc_id                  = aws_vpc.mwa_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1f"
  map_public_ip_on_launch = true

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_two" {
  vpc_id                  = aws_vpc.mwa_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_one" {
  vpc_id                  = aws_vpc.mwa_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_two" {
  vpc_id                  = aws_vpc.mwa_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    environment = var.environment
  }
}

// Create Internet Gateway, route table and attach them to the public subnet
resource "aws_internet_gateway" "mwa_internet_gateway" {
  vpc_id = aws_vpc.mwa_vpc.id

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "mwa_ig_route_table" {
  vpc_id = aws_vpc.mwa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mwa_internet_gateway.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table_association" "mwa_ra_public_subnet_one" {
  subnet_id      = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.mwa_ig_route_table.id
}

resource "aws_route_table_association" "mwa_ra_public_subnet_two" {
  subnet_id      = aws_subnet.public_subnet_two.id
  route_table_id = aws_route_table.mwa_ig_route_table.id
}

// Create NAT Gateways, route tables and attach them to the private subnet
resource "aws_eip" "mwa_eip_private_subnet_one_natgw" {
  vpc = true
  tags = {
    environment = var.environment
  }
}

resource "aws_eip" "mwa_eip_private_subnet_two_natgw" {
  vpc = true
  tags = {
    environment = var.environment
  }
}

resource "aws_nat_gateway" "private_subnet_one_natgw" {
  allocation_id = aws_eip.mwa_eip_private_subnet_one_natgw.id
  subnet_id     = aws_subnet.private_subnet_one.id
  tags = {
    environment = var.environment
  }
}

resource "aws_nat_gateway" "private_subnet_two_natgw" {
  allocation_id = aws_eip.mwa_eip_private_subnet_two_natgw.id
  subnet_id     = aws_subnet.private_subnet_two.id
  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "mwa_private_subnet_one_route_table" {
  vpc_id = aws_vpc.mwa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_subnet_one_natgw.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "mwa_private_subnet_two_route_table" {
  vpc_id = aws_vpc.mwa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_subnet_two_natgw.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table_association" "mwa_ra_private_subnet_one" {
  subnet_id      = aws_subnet.private_subnet_one.id
  route_table_id = aws_route_table.mwa_private_subnet_one_route_table.id
}

resource "aws_route_table_association" "mwa_ra_private_subnet_two" {
  subnet_id      = aws_subnet.private_subnet_two.id
  route_table_id = aws_route_table.mwa_private_subnet_two_route_table.id
}

//
