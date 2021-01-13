data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "web_cloudtrail" {
  name                          = "web-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = false
  enable_log_file_validation    = true

}

# block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "s3_cloudtrail_bucket_policy" {
  bucket                  = aws_s3_bucket.cloudtrail_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = var.cloudtrail_bucket_name
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.cloudtrail_bucket_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.cloudtrail_bucket_name}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

# notify if cloudtrail logs are deleted
resource "aws_s3_bucket_notification" "web_cloudtrail_notification" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  topic {
    topic_arn     = "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:NotifyMe"
    events        = ["s3:ObjectRemoved:*"]
    filter_prefix = "cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail-Digest/"
    filter_suffix = ".json.gz"
  }
}
