
resource "aws_guardduty_detector" "primary_detector" {
  enable = true
  tags = {
    environment = var.environment
  }
}

/*resource "aws_guardduty_filter" "MyFilter" {
  name        = "MyFilter"
  action      = "NOOP"
  detector_id = aws_guardduty_detector.primary_detector.id
  rank        = 1

  finding_criteria {
    criterion {
      field  = "region"
      equals = ["us-east-1"]
    }

    criterion {
      field                 = "severity"
      greater_than_or_equal = "4"
    }
  }
}*/
