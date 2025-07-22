

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "sketchy_main" {
  name = aws_eks_cluster.sketchy_main.name
}

data "aws_eks_cluster_auth" "sketchy_main" {
  name = aws_eks_cluster.sketchy_main.name
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sns_topic.security_notifications.arn]
  }
}