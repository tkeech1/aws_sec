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

  # allow http/https return traffic from the instance
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

resource "aws_instance" "public_server" {
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
}

/*
resource "aws_instance" "public_server_2" {
  ami                         = "ami-0947d2ba12ee1ff75"
  instance_type               = "t3.nano"
  iam_instance_profile        = aws_iam_instance_profile.web_ec2_instance_profile.name
  subnet_id                   = aws_subnet.public_subnet_2.id
  private_ip                  = "10.0.2.10"
  vpc_security_group_ids      = [aws_security_group.public_security_group.id]
  associate_public_ip_address = true
  user_data                   = file("./modules/ec2/user_data.tmpl")
  # create the web server after creating the cloudwatch event rule so a notification email is sent
  depends_on = [aws_cloudwatch_event_rule.web_running_event]

  tags = {
    environment = var.environment
  }
}
*/
