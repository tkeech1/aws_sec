resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    environment = var.environment
  }
}

// network acl for public subnet
resource "aws_network_acl" "public_subnet_nacl" {
  vpc_id     = aws_vpc.web_vpc.id
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  // allow external http traffic inbound on the listener port
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.ip_cidr
    from_port  = 80
    to_port    = 80
  }

  # allow http/https return traffic to the instance
  # https://inspector-agent.amazonaws.com/linux/latest/install
  # https://s3.dualstack.us-east-1.amazonaws.com/aws-agent.us-east-1/linux/latest/inspector.gpg
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  // traffic from private network destined for internet outbound through the public network
  ingress {
    protocol   = "tcp"
    rule_no    = 600
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 80
    to_port    = 80
  }

  // traffic from private network destined for internet outbound through the public network
  ingress {
    protocol   = "tcp"
    rule_no    = 700
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 443
    to_port    = 443
  }

  // allow outbound http so the instance can download and install packages
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  // allow outbound https so the instance can download and install packages
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  // allow web responses outbound
  egress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

}

// network acl for private subnet
resource "aws_network_acl" "private_subnet_nacl" {
  vpc_id     = aws_vpc.web_vpc.id
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  # allow http/https return traffic to the instance
  # https://inspector-agent.amazonaws.com/linux/latest/install
  # https://s3.dualstack.us-east-1.amazonaws.com/aws-agent.us-east-1/linux/latest/inspector.gpg
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # allow traffic from the SSM VPC endpoint
  ingress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 443
    to_port    = 443
  }

  // allow outbound http so the instance can download and install packages
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  // allow outbound https so the instance can download and install packages
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  // allow web responses outbound
  egress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

}


// public security group
resource "aws_security_group" "public_security_group" {
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    description = "allow access to the instance listener port from the load balancer"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "allow SSM access to the instance on HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "allow outbound http so the instance can download and install packages"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow outbound https so the instance can download and install packages"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}

// private security group
resource "aws_security_group" "private_security_group" {
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    description = "allow access to the instance listener port from the load balancer"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "allow SSM access to the instance on HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "allow outbound http so the instance can download and install packages"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow outbound https so the instance can download and install packages"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}

// vpc endpoint security group
resource "aws_security_group" "private_vpc_endpoint_security_group" {
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    description = "allow access to the instance listener port from the load balancer"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1f"

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1f"
  map_public_ip_on_launch = false

  tags = {
    environment = var.environment
  }
}

resource "aws_internet_gateway" "web_internet_gateway" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    environment = var.environment
  }
}

resource "aws_default_route_table" "web_default_route_table" {
  default_route_table_id = aws_vpc.web_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_internet_gateway.id
  }

  tags = {
    environment = var.environment
  }
}

// Create NAT Gateways, route tables and attach them to the PUBLIC subnet
resource "aws_eip" "web_eip_private_subnet_one_natgw" {
  vpc = true
  tags = {
    environment = var.environment
  }
}

resource "aws_eip" "web_eip_private_subnet_two_natgw" {
  vpc = true
  tags = {
    environment = var.environment
  }
}

resource "aws_nat_gateway" "private_subnet_one_natgw" {
  allocation_id = aws_eip.web_eip_private_subnet_one_natgw.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    environment = var.environment
  }
}

resource "aws_nat_gateway" "private_subnet_two_natgw" {
  allocation_id = aws_eip.web_eip_private_subnet_two_natgw.id
  subnet_id     = aws_subnet.public_subnet_2.id
  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "web_private_subnet_one_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_subnet_one_natgw.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "web_private_subnet_two_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_subnet_two_natgw.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table_association" "web_ra_private_subnet_one" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.web_private_subnet_one_route_table.id
}

resource "aws_route_table_association" "web_ra_private_subnet_two" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.web_private_subnet_two_route_table.id
}

/*
resource "aws_instance" "public_server_1" {
  ami                         = "ami-0947d2ba12ee1ff75"
  instance_type               = "t3.nano"
  iam_instance_profile        = aws_iam_instance_profile.web_ec2_instance_profile.name
  subnet_id                   = aws_subnet.public_subnet_1.id
  private_ip                  = "10.0.1.10"
  vpc_security_group_ids      = [aws_security_group.public_security_group.id]
  associate_public_ip_address = true
  user_data                   = file("./modules/ec2/user_data.tmpl")
  # create the web server after creating the cloudwatch event rule so a notification email is sent
  depends_on = [aws_cloudwatch_event_rule.web_running_event]

  tags = {
    environment = var.environment
  }
}*/

resource "aws_instance" "private_server_1" {
  ami                         = "ami-0947d2ba12ee1ff75"
  instance_type               = "t3.nano"
  iam_instance_profile        = aws_iam_instance_profile.web_ec2_instance_profile.name
  subnet_id                   = aws_subnet.private_subnet_1.id
  private_ip                  = "10.0.3.10"
  vpc_security_group_ids      = [aws_security_group.private_security_group.id]
  associate_public_ip_address = false
  user_data                   = file("./modules/ec2/user_data.tmpl")
  # create the web server after creating the cloudwatch event rule so a notification email is sent
  depends_on = [aws_cloudwatch_event_rule.web_running_event, aws_route_table_association.web_ra_private_subnet_one]

  tags = {
    environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint_ssm" {
  vpc_id            = aws_vpc.web_vpc.id
  service_name      = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.private_vpc_endpoint_security_group.id,
  ]
  subnet_ids          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  private_dns_enabled = true

  tags = {
    environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint_ec2messages" {
  vpc_id            = aws_vpc.web_vpc.id
  service_name      = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.private_vpc_endpoint_security_group.id,
  ]
  subnet_ids          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  private_dns_enabled = true

  tags = {
    environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint_ssmmessages" {
  vpc_id            = aws_vpc.web_vpc.id
  service_name      = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.private_vpc_endpoint_security_group.id,
  ]
  subnet_ids          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  private_dns_enabled = true

  tags = {
    environment = var.environment
  }
}
