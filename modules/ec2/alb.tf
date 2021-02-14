// load balancer security group
resource "aws_security_group" "load_balancer_security_group" {
  name   = "ec2-lb-security-group"
  vpc_id = var.vpc_id

  ingress {
    description = "allow inbound http to the load balancer on the lb listener port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #cidr_blocks = [var.ip_cidr] TODO
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow inbound https to the load balancer on the lb listener port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #cidr_blocks = [var.ip_cidr] TODO
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow outbout instance web traffic (responses to http traffic)"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow outbound 443 to communicate with amazon cognito to authenticate users"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}

// create an application load balancer
resource "aws_lb" "web_alb" {
  name                       = "web-alb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.load_balancer_security_group.id]
  subnets                    = [var.public_subnet_1_id, var.public_subnet_2_id]
  enable_deletion_protection = false

  access_logs {
    bucket  = "${var.log_bucket_name}-${var.environment}"
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
  vpc_id      = var.vpc_id
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
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

// create a network load balancer listener
resource "aws_lb_listener" "web_alb_front_end_https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_iam_server_certificate.self_signed_cert.arn

  /*default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = var.cognito_user_pool_arn
      user_pool_client_id = var.cognito_user_pool_client_id
      user_pool_domain    = var.cognito_domain
    }
  }*/

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_alb_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "web_targets_ps2" {
  target_group_arn = aws_lb_target_group.web_alb_target_group.arn
  target_id        = aws_instance.private_server_1.id
  port             = 8000
}

# create a bucket for ALB logs
resource "aws_s3_bucket" "s3_alb_logs" {
  bucket        = "${var.log_bucket_name}-${var.environment}"
  force_destroy = true

  # Enable server-side encryption 
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }

  tags = {
    environment = var.environment
  }
}

# block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "s3_alb_logs_bucket_policy" {
  bucket                  = aws_s3_bucket.s3_alb_logs.id
  depends_on              = [aws_s3_bucket.s3_alb_logs]
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_logging_policy" {
  bucket = aws_s3_bucket.s3_alb_logs.id

  # the account ID below is the account ID for the ELB in us east
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
  policy = <<POLICY
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::127311923021:root"
      },
      "Action" : "s3:PutObject",
      "Resource" : "arn:aws:s3:::${aws_s3_bucket.s3_alb_logs.bucket}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.s3_alb_logs.bucket}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "delivery.logs.amazonaws.com"
      },
      "Action" : "s3:GetBucketAcl",
      "Resource" : "arn:aws:s3:::${aws_s3_bucket.s3_alb_logs.bucket}"
    }
  ]
}
POLICY
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "self_signed_cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = var.environment
    organization = var.environment
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_iam_server_certificate" "self_signed_cert" {
  name_prefix      = "bandit-cert"
  certificate_body = tls_self_signed_cert.self_signed_cert.cert_pem
  private_key      = tls_private_key.private_key.private_key_pem

  lifecycle {
    create_before_destroy = true
  }

}
