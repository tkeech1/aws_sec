variable "environment" {
  type = string
}
variable "source_bucket_arn" {
  type = string
}
variable "log_bucket_name" {
  type = string
}
variable "ip_cidr" {
  type = string
}
variable "sse_algorithm" {
  type = string
}
variable "cognito_user_pool_arn" {
  type = string
}
variable "cognito_user_pool_client_id" {
  type = string
}
variable "cognito_domain" {
  type = string
}
