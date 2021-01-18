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
