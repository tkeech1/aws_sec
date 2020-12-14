/* commented out for testing - the config works as-is
resource "aws_wafv2_web_acl" "web_waf_acl" {
  name  = "web-acl-web_waf_acl-example"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }

  # use an ipset for whitelisting IPs
  rule {
    name     = "ip-whitelist"
    priority = 1

    action {
      allow {}
    }

    statement {

      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.web_ip_set.arn
      }

    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "ip-whitelist"
      sampled_requests_enabled   = false
    }
  }

  # AWS managed rule set
  rule {
    name     = "managed-rules"
    priority = 2

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-common-rules"
      sampled_requests_enabled   = false
    }
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_wafv2_web_acl_association" "web_waf_acl_association" {
  resource_arn = aws_lb.web_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.web_waf_acl.arn
}

resource "aws_wafv2_ip_set" "web_ip_set" {
  name               = "web-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["108.16.31.89/32"]
}
*/
