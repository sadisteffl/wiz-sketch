

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


data "aws_partition" "current" {}

data "aws_eks_cluster" "sketch-ai-cluster" {
  name = aws_eks_cluster.sketch-ai-cluster.name
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