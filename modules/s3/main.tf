resource "aws_s3_bucket" "s3_source_code" {
  bucket        = "${var.source_bucket_name}-${var.environment}"
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
resource "aws_s3_bucket_public_access_block" "s3_source_code_bucket_policy" {
  bucket                  = aws_s3_bucket.s3_source_code.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "s3_alb_logs" {
  bucket        = "${var.logs_bucket_name}-${var.environment}"
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
