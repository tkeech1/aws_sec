output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.user_pool.arn
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "cognito_service_id_pool_client_id" {
  value = aws_cognito_user_pool_client.service_id_user_pool_client.id
}

output "cognito_domain" {
  value = aws_cognito_user_pool_domain.cognito_domain.domain
}
