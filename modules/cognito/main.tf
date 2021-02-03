resource "aws_cognito_user_pool" "user_pool" {
  name = "BanditUserPool"
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                                 = "BanditUserPoolClient"
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  callback_urls                        = ["https://${var.alb_dns_name}/oauth2/idpresponse", "https://${var.alb_ecs_dns_name}/oauth2/idpresponse"]
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_pool_client" "ecs_user_pool_client" {
  name                                 = "BanditECSUserPoolClient"
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  callback_urls                        = ["https://${var.alb_ecs_dns_name}/oauth2/idpresponse", "https://${var.alb_dns_name}/oauth2/idpresponse"]
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
}


resource "aws_cognito_resource_server" "resource" {
  identifier = "bandit-resource-server"
  name       = "example"

  scope {
    scope_name        = "sample-scope"
    scope_description = "a Sample Scope Description"
  }

  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_pool_client" "service_id_user_pool_client" {
  name                                 = "ServiceIDUserPoolClient"
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes                 = ["bandit-resource-server/sample-scope"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  callback_urls                        = ["https://${var.alb_dns_name}/oauth2/idpresponse"]
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  depends_on                           = [aws_cognito_resource_server.resource]
}

resource "aws_cognito_user_pool_domain" "cognito_domain" {
  domain       = "tdk"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}


resource null_resource cognito_users {
  depends_on = [aws_cognito_user_pool.user_pool]
  #for_each   = var.cognito_users
  provisioner local-exec {
    command = "aws cognito-idp admin-create-user --user-pool-id ${aws_cognito_user_pool.user_pool.id} --username ${var.cognito_user} --user-attributes Name=email,Value=${var.cognito_user}"
  }
}
