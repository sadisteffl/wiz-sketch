resource "aws_securityhub_account" "this" {}

resource "aws_securityhub_standards_subscription" "foundational_best_practices" {
  depends_on = [aws_securityhub_account.this]

  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_kms_key" "cloudtrail_key" {
  description             = "KMS key for encrypting CloudTrail and CloudWatch logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "cloudtrail_key_policy" {
  key_id = aws_kms_key.cloudtrail_key.id
  policy = data.aws_iam_policy_document.cloudtrail_key_policy.json
}

data "aws_iam_policy_document" "cloudtrail_key_policy" {
  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      aws_kms_key.cloudtrail_key.arn
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        data.aws_caller_identity.current.arn
      ]
    }
  }

  statement {
    sid       = "AllowCloudTrailService"
    effect    = "Allow"
    actions   = ["kms:DescribeKey", "kms:GenerateDataKey*", "kms:Decrypt"]
    resources = [aws_kms_key.cloudtrail_key.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogsService"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.cloudtrail_key.arn]
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "general_service_key" {
  description             = "KMS key for ECR/EKS or other repositories"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "general_service_key_policy" {
  key_id = aws_kms_key.general_service_key.id
  policy = data.aws_iam_policy_document.general_service_key_policy.json
}

data "aws_iam_policy_document" "general_service_key_policy" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"] # This should be scoped to the key ARN for best practice
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        data.aws_caller_identity.current.arn
      ]
    }
  }
  statement {
    sid       = "AllowCloudWatchLogsService"
    effect    = "Allow"
    actions   = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
    resources = ["*"] # This should be scoped to the key ARN for best practice
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

data "aws_guardduty_detector" "this" {}

resource "aws_sns_topic" "guardduty_notifications" {
  name_prefix       = "guardduty-high-severity-findings-"
  kms_master_key_id = aws_kms_key.general_service_key.arn
}

resource "aws_sns_topic_subscription" "guardduty_email_alert" {
  topic_arn = aws_sns_topic.guardduty_notifications.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_event_rule" "guardduty_high_severity_rule" {
  name_prefix = "guardduty-high-severity-rule-"
  description = "Triggers on critical or high severity GuardDuty findings."
  event_pattern = jsonencode({
    source        = ["aws.guardduty"],
    "detail-type" = ["GuardDuty Finding"],
    detail = {
      severity = [{ "numeric" : [">=", 7] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_high_severity_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_notifications.arn
}

resource "aws_sns_topic_policy" "allow_eventbridge_to_guardduty_topic" {
  arn    = aws_sns_topic.guardduty_notifications.arn
  policy = data.aws_iam_policy_document.sns_eventbridge_policy.json
}

data "aws_iam_policy_document" "sns_eventbridge_policy" {
  statement {
    sid       = "AllowEventBridgeToPublish"
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.guardduty_notifications.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name_prefix       = "aws-cloudtrail-logs-"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudtrail_key.arn
  depends_on        = [aws_kms_key_policy.cloudtrail_key_policy]
}

resource "aws_sns_topic" "cloudtrail_notifications" {
  name_prefix       = "cloudtrail-activity-notifications-"
  kms_master_key_id = aws_kms_key.cloudtrail_key.arn
}

resource "aws_sns_topic_policy" "cloudtrail_sns_policy" {
  arn    = aws_sns_topic.cloudtrail_notifications.arn
  policy = data.aws_iam_policy_document.cloudtrail_sns_policy_doc.json
}

data "aws_iam_policy_document" "cloudtrail_sns_policy_doc" {
  statement {
    sid    = "AllowCloudTrailToPublish"
    effect = "Allow"
    actions = [
      "SNS:Publish",
    ]
    resources = [
      aws_sns_topic.cloudtrail_notifications.arn,
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_cloudtrail" "this" {
  name                          = "wiz-exercise-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_role.arn
  sns_topic_name                = aws_sns_topic.cloudtrail_notifications.name

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_bucket_policy,
    aws_iam_role_policy.cloudtrail_cloudwatch_policy,
    aws_sns_topic_policy.cloudtrail_sns_policy
  ]
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_insight_alarm" {
  alarm_name          = "CloudTrail-Insight-Activity-Detected"
  alarm_description   = "Triggered when unusual API activity is detected by CloudTrail Insights."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "InsightEventCount"
  namespace           = "CloudTrail/Insights"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.guardduty_notifications.arn]
}

resource "aws_cloudwatch_log_group" "exploit_app_logs" {
  name_prefix       = "/eks/sketchy-frontend-app-"
  retention_in_days = 365 # Changed from 7 to 365 for better retention
  kms_key_id        = aws_kms_key.general_service_key.arn

  tags = {
    Project = "SketchyApp"
    Purpose = "Application Logging"
  }
}

resource "aws_cloudwatch_log_metric_filter" "exploit_detection_filter" {
  name           = "NvidiaExploitPattern"
  pattern        = "{ $.message = \"File /owned created\" }"
  log_group_name = aws_cloudwatch_log_group.exploit_app_logs.name

  metric_transformation {
    name      = "ExploitFound"
    namespace = "ApplicationSecurity"
    value     = "1"
  }
}

resource "aws_sns_topic" "exploit_alerts" {
  name_prefix       = "critical-security-exploit-alerts-"
  kms_master_key_id = aws_kms_key.general_service_key.arn
  tags = {
    Project = "SketchyApp"
    Purpose = "Security Alerting"
  }
}

resource "aws_sns_topic_subscription" "exploit_email_target" {
  topic_arn = aws_sns_topic.exploit_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_email
}

resource "aws_cloudwatch_metric_alarm" "exploit_detected_alarm" {
  alarm_name          = "High-Severity-Exploit-Detected-NvidiaScape"
  alarm_description   = "This alarm triggers when a log event matches the pattern for a specific container escape exploit."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.exploit_detection_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.exploit_detection_filter.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.exploit_alerts.arn]
  ok_actions          = [aws_sns_topic.exploit_alerts.arn]
  tags = {
    Project  = "SketchyApp"
    Severity = "Critical"
  }
}

resource "aws_sns_topic" "security_notifications" {
  name_prefix = "security-event-notifications-"

  kms_master_key_id = aws_kms_key.general_service_key.arn
}

resource "aws_wafv2_web_acl" "sketchy_waf" {
  name  = "sketchy_waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-sqli-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 40

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-linux-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 50

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_kms_key" "ecr_eks_repository_cmk" {
  description             = "KMS key for ECR and EKS secrets encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow ECR service to use the key",
        Effect = "Allow",
        Principal = {
          Service = "ecr.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow EKS service to encrypt and decrypt secrets",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = [
          "kms:CreateGrant",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name         = "ECR_EKS_SharedCMK"
    Environment  = "Production"
    ManagedBy    = "Terraform"
    ProjectOwner = "Sadi"
  }
}

data "aws_ssm_parameter" "eks_gpu_ami" {
  name = "/aws/service/eks/optimized-ami/1.33/amazon-linux-2023/arm64/nvidia/amazon-eks-node-al2023-arm64-nvidia-1.33-v20250704/image_id"
}



resource "aws_launch_template" "gpu_nodes_lt" {
  name_prefix = "gpu-nodes-lt-"

  image_id = data.aws_ssm_parameter.eks_gpu_ami.value

  instance_type = "g5g.xlarge"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "gpu-eks-node"
    }
  }
}