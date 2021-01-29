// private security group
resource "aws_security_group" "private_security_group" {
  vpc_id = var.vpc_id

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
  #ami                         = "ami-0947d2ba12ee1ff75"
  ami                         = "ami-0be2609ba883822ec"
  instance_type               = "t3.nano"
  iam_instance_profile        = aws_iam_instance_profile.web_ec2_instance_profile.name
  subnet_id                   = var.private_subnet_1_id
  private_ip                  = "10.0.3.10"
  vpc_security_group_ids      = [aws_security_group.private_security_group.id]
  associate_public_ip_address = false
  user_data                   = file("./modules/ec2/user_data.tmpl")
  # create the web server after creating the cloudwatch event rule so a notification email is sent
  depends_on = [aws_cloudwatch_event_rule.web_running_event]

  tags = {
    environment = var.environment
  }
}


