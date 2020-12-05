output "source_bucket_arn" {
  value = aws_s3_bucket.s3_source_code.arn
}
output "source_bucket_name" {
  value = aws_s3_bucket.s3_source_code.bucket
}
output "logs_bucket_arn" {
  value = aws_s3_bucket.s3_alb_logs.arn
}
output "logs_bucket_name" {
  value = aws_s3_bucket.s3_alb_logs.bucket
}
