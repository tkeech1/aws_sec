
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "web_log_group" {
  name              = "web_log_group"
  retention_in_days = 1
  #kms_key_id = 

  tags = {
    environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "flow_log_group"
  retention_in_days = 1
  #kms_key_id = 

  tags = {
    environment = var.environment
  }
}

resource "aws_cloudwatch_log_stream" "web_log_stream" {
  name           = "web_log_stream"
  log_group_name = aws_cloudwatch_log_group.web_log_group.name
}

resource "aws_cloudwatch_event_rule" "web_running_event" {
  name        = "web-running-event"
  description = "Alert when web server is running"

  event_pattern = <<EOF
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "running"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "web_running_event_target" {
  target_id = "web-running-event-target"
  rule      = aws_cloudwatch_event_rule.web_running_event.name
  arn       = "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:NotifyMe"
}
