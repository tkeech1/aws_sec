
resource "aws_ecr_repository" "ecr_repo" {
  name                 = "bandit_repo/service"
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    environment = var.environment
  }
}
