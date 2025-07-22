resource "aws_sns_topic" "billing_alerts" {
  name = "BillingAlertsTopic"

  kms_master_key_id = aws_kms_key.ecr_eks_repository_cmk.arn

  tags = {
    Project = "SketchyApp"
    Purpose = "Cost Management"
  }
}

resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint = "sadisteffl@gmail.com"
}

resource "aws_budgets_budget" "daily_cost_limit" {
  name         = "Daily-Cost-Limit-20-USD"
  budget_type  = "COST"
  limit_amount = "20"
  limit_unit   = "USD"
  time_unit    = "DAILY"


  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.billing_alerts.arn]
  }

  tags = {
    Project = "SketchyApp"
    Purpose = "Cost Management"
  }
}