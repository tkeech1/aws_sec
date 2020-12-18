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
    cidr_block = "108.16.31.89/32"
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
    description = "allow access to the instnace listener port from the load balancer"
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

// load balancer security group
resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    description = "allow inbound http to the load balancer on the lb listener port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["108.16.31.89/32"]
  }

  egress {
    description = "allow outbout instance web traffic (responses to http traffic)"
    from_port   = 1024
    to_port     = 65535
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

# create the public key to connect to the ec2 instance
resource "aws_key_pair" "ec2_public_key" {
  key_name   = "todd@tk"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9E7yCIHpNKaHXtzxFnKJPT+gtyXAnprq/pCfs/fPW+sXwAAFVsIt0rzEghkSshR8lUcyGJTafOFLPIAfSHirp2JdREtWa3CijokSHzaoSk2PrB8KzrX07l998lYGVgKzsOb8TmeLAeHR/vgwQ0r7r/17JOIRLrYcaghkrpwDt/GPVCxZa8TjQWiyX9Aw+QRP4IX6N65py5y2dsh7+GOS/rIlueRDx7YVEhzA8OvhiN2v0EW8QtdHhWU6uEOpuPF16sXYTImb73BnsjE+CZWrkjAlIp35hbuw1E2jZWAWnA10txc5VadjemPsPysCBMkEBYDl/DAdFQ0YlB5G3DKBD todd@tk"
}

resource "aws_instance" "public_server" {
  ami                         = "ami-0947d2ba12ee1ff75"
  instance_type               = "t3.nano"
  key_name                    = aws_key_pair.ec2_public_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.web_ec2_instance_profile.name
  subnet_id                   = aws_subnet.public_subnet_1.id
  private_ip                  = "10.0.1.10"
  vpc_security_group_ids      = [aws_security_group.public_security_group.id]
  associate_public_ip_address = true
  user_data                   = file("./modules/ec2/user_data.tmpl")
  #depends_on                  = [aws_nat_gateway.public_subnet_1_natgw, aws_nat_gateway.public_subnet_2_natgw]

  tags = {
    environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "web_log_group" {
  name              = "web_log_group"
  retention_in_days = 1
  #kms_key_id = 

  tags = {
    environment = var.environment
  }
}

resource "aws_cloudwatch_log_stream" "web_log_stream" {
  name           = "web_log_stream"
  log_group_name = aws_cloudwatch_log_group.web_log_group.name
}
