/*resource "aws_api_gateway_vpc_link" "api_gateway" {
  name        = "api_gateway"
  description = "API Gateway frontend for NLB"
  target_arns = [var.target_arns]
  tags = {
    environment = var.environment
  }
}*/

// apigateway security group
resource "aws_security_group" "api_gateway_vpc_link_security_group" {
  vpc_id = var.vpc_id

  ingress {
    description = "allow inbound http to the load balancer on the lb listener port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_apigatewayv2_vpc_link" "api_gateway" {
  name               = "api_gateway"
  security_group_ids = [aws_security_group.api_gateway_vpc_link_security_group.id]
  subnet_ids         = var.subnet_ids

  tags = {
    environment = var.environment
  }
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "rest_api" {
  name = "rest_api"
  #body        = templatefile("./modules/api_gateway/api-swagger.json", { region = var.region, account_id = data.aws_caller_identity.current.account_id, cognito_user_pool_id = var.cognito_user_pool_id, vpc_link_id = aws_api_gateway_vpc_link.mwa_api_gateway.id, nlb_dns_name = aws_lb.mwa_nlb.dns_name })
  body = templatefile("./modules/api_gateway/open_api3.json", {})

  tags = {
    environment = var.environment
  }
}


resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = var.environment

  lifecycle {
    create_before_destroy = true
  }

}
