resource "aws_cognito_user_pool" "user_pool" {
  name                     = "BanditUserPool"
  auto_verified_attributes = ["email"]

  tags = {
    environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name = "BanditUserPoolClient"

  user_pool_id = aws_cognito_user_pool.user_pool.id
}
