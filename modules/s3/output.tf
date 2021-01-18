output "source_bucket_arn" {
  value = aws_s3_bucket.s3_source_code.arn
}
output "source_bucket_name" {
  value = aws_s3_bucket.s3_source_code.bucket
}
