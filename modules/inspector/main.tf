resource "aws_inspector_resource_group" "web_resource_group" {
  tags = {
    environment = var.environment
  }
}

resource "aws_inspector_assessment_target" "web_target" {
  name               = "web_target"
  resource_group_arn = aws_inspector_resource_group.web_resource_group.arn
}

resource "aws_inspector_assessment_template" "web_assessment_template" {
  name       = "example"
  target_arn = aws_inspector_assessment_target.web_target.arn
  duration   = 3600

  # security best practices
  # common CVEs
  # CIS benchmarks
  rules_package_arns = [
    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-R01qwB5Q",
    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7",
    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-rExsr2X8",
  ]
}

# TODO - run an assessment from boto3 - no way to run through terraform
