resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = true

  tags = {
    environment = var.environment
  }
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.web_vpc.default_network_acl_id

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

resource "aws_default_security_group" "web_security_group" {
  vpc_id = aws_vpc.web_vpc.id

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

resource "aws_subnet" "web_subnet" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "10.0.0.0/24"
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

resource "aws_instance" "web_server" {
  ami                         = "ami-0947d2ba12ee1ff75"
  instance_type               = "t3.nano"
  key_name                    = aws_key_pair.ec2_public_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.web_ec2_instance_profile.name
  subnet_id                   = aws_subnet.web_subnet.id
  private_ip                  = "10.0.0.10"
  vpc_security_group_ids      = [aws_default_security_group.web_security_group.id]
  associate_public_ip_address = true
  user_data                   = file("./modules/ec2/user_data.tmpl")
  tags = {
    environment = var.environment
  }
}

resource "aws_eip" "web_eip" {
  instance                  = aws_instance.web_server.id
  vpc                       = true
  associate_with_private_ip = "10.0.0.10"
  depends_on                = [aws_internet_gateway.web_internet_gateway]

  tags = {
    environment = var.environment
  }
}
