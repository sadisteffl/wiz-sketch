resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_kms_key" "eks_secrets_key" {
  description = "KMS key for EKS secret encryption"

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
      }
    ]
  })
}

resource "aws_eks_cluster" "sketch-ai-cluster" {
  name     = "sketch-ai-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_az1.id,
      aws_subnet.public_az2.id
    ]
    endpoint_public_access  = false
    endpoint_private_access = true
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets_key.arn
    }
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy
  ]
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# iam.tf

# 1. Create a policy to allow decryption using the EKS secrets key
resource "aws_iam_policy" "eks_secrets_decrypt" {
  name        = "eks-secrets-decrypt-policy"
  description = "Allows EKS worker nodes to decrypt secrets encrypted with the cluster KMS key"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "kms:Decrypt",
        Resource = aws_kms_key.eks_secrets_key.arn
      }
    ]
  })
}

# 2. Attach the policy to the EKS worker node role
resource "aws_iam_role_policy_attachment" "eks_node_secrets_decrypt_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.eks_secrets_decrypt.arn
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "sketch_nodes" {
  cluster_name    = aws_eks_cluster.sketch-ai-cluster.name
  node_group_name = "sketch_nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  ami_type      = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"

  tags = {
    Name = "Free Tier Node Group"
  }
}

data "aws_iam_policy_document" "csi_driver_trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    # This condition trusts the service account used by the CSI driver pods
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:csi-secrets-store-provider-aws"]
    }
  }
}

# Attach the ECR Read-Only policy to the EKS node role
resource "aws_iam_role_policy_attachment" "ecr_read_only_for_nodes" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}