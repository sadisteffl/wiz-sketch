resource "aws_ecr_repository" "sketchy_frontend_app" {
  name = "sketchy-frontend-app"

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_eks_repository_cmk.arn
  }

  tags = {
    Name         = "frontend-app"
    Project      = "SketchApp"
    Component    = "Frontend"
    Environment  = "Development"
    ManagedBy    = "Terraform"
    ProjectOwner = "Sadi"
  }
}

resource "aws_ecr_repository" "sketchy_backend_app" {
  name = "sketchy-backend-app"

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_eks_repository_cmk.arn


  }

  tags = {
    Name         = "backend-app"
    Project      = "SketchyApp"
    Component    = "Backend"
    Environment  = "Development"
    ManagedBy    = "Terraform"
    ProjectOwner = "Sadi"
  }
}