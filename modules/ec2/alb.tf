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