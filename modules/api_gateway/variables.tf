variable "environment" {
  type = string
}
variable "region" {
  type = string
}
variable "cognito_user_pool_id" {
  type = string
}
variable "alb_dns_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list
}
