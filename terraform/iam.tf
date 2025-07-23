
# MongoDV - VM
resource "aws_iam_role" "overly_permissive_role" {
  name = "db-vm-overly-permissive-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attachment" {
  role       = aws_iam_role.overly_permissive_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "sketchy_mongoprofile" {
  name = "sketchy_mongoprofile"
  role = aws_iam_role.overly_permissive_role.name
}

# EKS OIDC Provider
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"]
}

# Secrets Manager & IRSA
resource "aws_iam_policy" "secretsmanager_access" {
  name        = "SecretsManagerSketchyDrawAccess"
  description = "Allows pod to read secrets from AWS Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = "arn:aws:secretsmanager:*:*:secret:sketchydraw/backend*"
    }]
  })
}

resource "aws_iam_role" "k8s_sa_sketchydraw" {
  name = "IRSA-SketchyDraw"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:default:sa-sketchydraw"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secretsmanager_access" {
  role       = aws_iam_role.k8s_sa_sketchydraw.name
  policy_arn = aws_iam_policy.secretsmanager_access.arn
}

# CloudTrail Roles
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "cloudtrail-cloudwatch-role-${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "cloudtrail-cloudwatch-policy-${random_id.suffix.hex}"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "CloudWatchLogsPermission",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
      },
      {
        Sid      = "KMSKeyPermission",
        Action   = ["kms:Encrypt", "kms:DescribeKey"],
        Effect   = "Allow",
        Resource = aws_kms_key.cloudtrail_key.arn
      }
    ]
  })
}


# ------------------------------------------------------------------------------
# Data source to get your existing GitHub OIDC Provider
# ------------------------------------------------------------------------------
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ------------------------------------------------------------------------------
# IAM Role and Policy for ECR Access from GitHub Actions
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_actions_ecr_role" {
  name = "github-actions-ecr-role"

  # Trust policy that allows GitHub Actions to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          # References your existing OIDC provider
          Federated = data.aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            # This condition restricts the role to your specific GitHub repository.
            # Replace <YOUR-GITHUB-USERNAME> and <YOUR-REPO-NAME> with your details.
            "token.actions.githubusercontent.com:sub" = "repo:<YOUR-GITHUB-USERNAME>/<YOUR-REPO-NAME>:*"
          }
        }
      }
    ]
  })

  tags = {
    Description = "IAM role for GitHub Actions to push images to ECR"
  }
}

resource "aws_iam_policy" "github_actions_ecr_policy" {
  name        = "GitHubActionsECRPolicy"
  description = "Policy for GitHub Actions to access ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowECRLogin",
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      },
      {
        Sid    = "AllowECRImagePush",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],

        Resource = [
          aws_ecr_repository.sketchy_frontend_app.arn,
          aws_ecr_repository.sketchy_backend_app.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr_attachment" {
  role       = aws_iam_role.github_actions_ecr_role.name
  policy_arn = aws_iam_policy.github_actions_ecr_policy.arn
}