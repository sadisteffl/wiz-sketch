
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
