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

  // inbound ssh
  /*ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "108.16.31.89/32"
    from_port  = 22
    to_port    = 22
  }*/

  // ssh access for AWS Instance Connect
  // not needed
  /*ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "18.206.107.24/29"
    from_port  = 22
    to_port    = 22
  }*/

  // allow external http traffic inbound on the listener port
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "108.16.31.89/32"
    from_port  = 80
    to_port    = 80
  }

  # allows the load balancer to communicate to the instance in a public subnet
  /*ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 80
    to_port    = 80
  }*/

  # allows the private subnet to communicate out to Internet through the public subnet
  /*ingress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 443
    to_port    = 443
  }*/

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

  /*egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }*/

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

/*
// network acl for private subnet
resource "aws_network_acl" "private_subnet_nacl" {
  vpc_id     = aws_vpc.web_vpc.id
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 22
    to_port    = 22
  }

  // allow all traffic to load balancer on listener port
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 8000
    to_port    = 8000
  }

  # allow https return traffic from https://inspector-agent.amazonaws.com/linux/latest/install
  # https://s3.dualstack.us-east-1.amazonaws.com/aws-agent.us-east-1/linux/latest/inspector.gpg
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
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
*/


// public security group
resource "aws_security_group" "public_security_group" {
  vpc_id = aws_vpc.web_vpc.id

  // inbound ssh from AWS instance connect
  /* not needed for AWS instance connect
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["108.16.31.89/32", "18.206.107.24/29"]
  }
  */

  // inbound on instance listener port (direct access to instance)
  /*ingress {
    description = "Web traffic"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }*/

  // allow access to the instnace listener port from the load balancer
  ingress {
    description = "Web traffic"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  /*
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }*/

  // allow outbound http so the instance can download and install packages
  egress {
    description = "Web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // allow outbound https so the instance can download and install packages
  egress {
    description = "Web traffic"
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

  // allow inbound to the load balancer on the lb listener port
  ingress {
    description = "Web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["108.16.31.89/32"]
  }

  // allow outbout instance web traffic (responses to http traffic)
  egress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}

/*
// private security group
resource "aws_security_group" "private_security_group" {
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    description = "SSH from home and EC2 Instance Connect"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Web traffic"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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
*/

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

/*
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1f"

  tags = {
    environment = var.environment
  }
}
*/

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

/*
// Create NAT Gateways, route tables and attach them to the PUBLIC subnet
resource "aws_eip" "web_eip_public_subnet_1_natgw" {
  vpc = true
  tags = {
    environment = var.environment
  }
}

resource "aws_eip" "web_eip_public_subnet_2_natgw" {
  vpc = true
  tags = {
    environment = var.environment
  }
}

resource "aws_nat_gateway" "public_subnet_1_natgw" {
  allocation_id = aws_eip.web_eip_public_subnet_1_natgw.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    environment = var.environment
  }
}

resource "aws_nat_gateway" "public_subnet_2_natgw" {
  allocation_id = aws_eip.web_eip_public_subnet_2_natgw.id
  subnet_id     = aws_subnet.public_subnet_2.id
  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "web_private_subnet_1_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public_subnet_1_natgw.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table" "web_private_subnet_2_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public_subnet_2_natgw.id
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_route_table_association" "web_ra_private_subnet_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.web_private_subnet_1_route_table.id
}

resource "aws_route_table_association" "mwa_ra_private_subnet_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.web_private_subnet_2_route_table.id
}
*/

# create the public key to connect to the ec2 instance
resource "aws_key_pair" "ec2_public_key" {
  key_name   = "todd@tk"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9E7yCIHpNKaHXtzxFnKJPT+gtyXAnprq/pCfs/fPW+sXwAAFVsIt0rzEghkSshR8lUcyGJTafOFLPIAfSHirp2JdREtWa3CijokSHzaoSk2PrB8KzrX07l998lYGVgKzsOb8TmeLAeHR/vgwQ0r7r/17JOIRLrYcaghkrpwDt/GPVCxZa8TjQWiyX9Aw+QRP4IX6N65py5y2dsh7+GOS/rIlueRDx7YVEhzA8OvhiN2v0EW8QtdHhWU6uEOpuPF16sXYTImb73BnsjE+CZWrkjAlIp35hbuw1E2jZWAWnA10txc5VadjemPsPysCBMkEBYDl/DAdFQ0YlB5G3DKBD todd@tk"
}

/*
resource "aws_instance" "web_server" {
  ami                         = "ami-0947d2ba12ee1ff75"
  instance_type               = "t3.nano"
  key_name                    = aws_key_pair.ec2_public_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.web_ec2_instance_profile.name
  subnet_id                   = aws_subnet.private_subnet_1.id
  private_ip                  = "10.0.3.10"
  vpc_security_group_ids      = [aws_security_group.private_security_group.id]
  associate_public_ip_address = false
  user_data                   = file("./modules/ec2/user_data.tmpl")
  depends_on                  = [aws_nat_gateway.public_subnet_1_natgw, aws_nat_gateway.public_subnet_2_natgw]

  tags = {
    environment = var.environment
  }
}*/

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

// create an application load balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  #subnets                    = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  subnets                    = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  enable_deletion_protection = false

  access_logs {
    bucket  = var.log_bucket_name
    enabled = true
  }

  tags = {
    environment = var.environment
  }
}

// create a load balancer target group
resource "aws_lb_target_group" "web_alb_target_group" {
  name        = "web-alb-target-group"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.web_vpc.id
  health_check {
    interval            = 10
    path                = "/"
    port                = 8000
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    environment = var.environment
  }
}

// create a network load balancer listener
resource "aws_lb_listener" "web_alb_front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_alb_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "web_targets" {
  target_group_arn = aws_lb_target_group.web_alb_target_group.arn
  target_id        = aws_instance.public_server.id
  port             = 8000
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
