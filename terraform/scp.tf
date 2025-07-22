data "aws_organizations_organization" "org" {}

resource "aws_organizations_policy" "deny_wildcard_permissions" {
  name        = "DenyWildcardPermissions"
  description = "Prevents attaching policies that grant '*' permissions to any IAM entity."
  content = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DenyPolicyWithStarActionOrResource",
        "Effect" : "Deny",
        "Action" : [
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:PutRolePolicy",
          "iam:PutUserPolicy",
          "iam:PutGroupPolicy",
          "iam:AttachUserPolicy",
          "iam:AttachGroupPolicy",
          "iam:AttachRolePolicy"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLikeIfExists" : {
            "iam:PolicyDocument" : "*\"Action\":\"*\"*"
          }
        }
      }
    ]
  })
  type = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "boundary_policy_attachment" {
  policy_id = aws_organizations_policy.deny_wildcard_permissions.id
  target_id = "r-bybs"
}
