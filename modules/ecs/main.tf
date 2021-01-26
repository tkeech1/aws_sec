resource "aws_ecs_cluster" "bandit_cluster" {
  name = "bandit_cluster"
  tags = {
    environment = var.environment
  }
}

// private security group
resource "aws_security_group" "private_security_group" {
  vpc_id = var.vpc_id

  ingress {
    description = "allow access to the instance listener port from the load balancer"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "allow outbound https to pull container images"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "bandit_log_group" {
  name              = "bandit_log_group"
  retention_in_days = 1

  tags = {
    environment = var.environment
  }
}

resource "aws_ecs_task_definition" "bandit_ecs_task_definition" {
  family                   = "bandit_ecs_task_definition"
  execution_role_arn       = aws_iam_role.bandit_ecs_role.arn
  task_role_arn            = aws_iam_role.bandit_ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"

  container_definitions = templatefile("./modules/ecs/task-definition.json", { ecr_image_tag = var.ecr_image_tag, bandit_log_group = aws_cloudwatch_log_group.bandit_log_group.name })

  tags = {
    environment = var.environment
  }
}

resource "aws_ecs_service" "bandit_http_service" {
  name                               = "bandit_http_service"
  cluster                            = aws_ecs_cluster.bandit_cluster.id
  task_definition                    = aws_ecs_task_definition.bandit_ecs_task_definition.arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1

  network_configuration {
    subnets          = [var.private_subnet_1_id, var.private_subnet_2_id]
    security_groups  = [aws_security_group.private_security_group.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_target_group.arn
    container_name   = "bandit-Service"
    container_port   = 8000
  }

  depends_on = [aws_lb_target_group.ecs_alb_target_group, aws_lb.ecs_alb, aws_lb_listener.ecs_alb_front_end_https]

}
