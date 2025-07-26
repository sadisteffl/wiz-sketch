resource "aws_instance" "db_server" {
  ami                    = "ami-020cba7c55df1f615"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_az1.id
  vpc_security_group_ids = [aws_security_group.db_vm.id]
  iam_instance_profile   = aws_iam_instance_profile.mongo_instance_profile.name
  key_name               = "test"
  monitoring             = true
  ebs_optimized          = true

  # Securely pass the secret ARNs to the user_data script
  user_data = templatefile("${path.module}/user_data.sh", {
    db_user                = var.db_user
    s3_bucket_name         = aws_s3_bucket.mongodb-backup.bucket
    mongo_admin_secret_arn = aws_secretsmanager_secret.mongo_manager.arn
    mongo_user_secret_arn  = aws_secretsmanager_secret.mongo_user_secret.arn
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name  = "wiz-exercise-db-vm"
    Owner = "Sadi"
  }
}


# Admin User
resource "random_password" "mongo_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "mongo_manager" {
  name       = "mongodb/admin/password"
  kms_key_id = aws_kms_key.general_service_key.arn
  tags = {
    Description = "MongoDB admin password"
  }
}

resource "aws_secretsmanager_secret_version" "mongo_secret_manager_version" {
  secret_id     = aws_secretsmanager_secret.mongo_manager.id
  secret_string = random_password.mongo_admin_password.result
}

# Application User
resource "random_password" "mongo_user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# This secret stores the app user's password for the user_data script to fetch
resource "aws_secretsmanager_secret" "mongo_user_secret" {
  name       = "mongodb/user/password"
  kms_key_id = aws_kms_key.general_service_key.arn
  tags = {
    Description = "MongoDB sketchydb application user password"
  }
}

resource "aws_secretsmanager_secret_version" "mongo_user_secret_version" {
  secret_id     = aws_secretsmanager_secret.mongo_user_secret.id
  secret_string = random_password.mongo_user_password.result
}

# This is the secret that will be used by Kubernetes (contains the full URI)
resource "aws_secretsmanager_secret" "sketchy_backend_secret" {
  # CHANGED: The secret name is now different to avoid conflicts.
  name       = "sketchydraw_back"
  kms_key_id = aws_kms_key.general_service_key.arn
  tags = {
    Description = "MongoDB connection URI for SketchyDraw backend"
  }
}

resource "aws_secretsmanager_secret_version" "sketchy_backend_secret_version" {
  secret_id = aws_secretsmanager_secret.sketchy_backend_secret.id
  secret_string = jsonencode({
    DB_URI = "mongodb://${var.db_user}:${random_password.mongo_user_password.result}@${aws_instance.db_server.private_ip}:27017/sketchydb?authSource=admin"
  })
}

resource "aws_iam_role" "mongo_instance_role" {
  name = "mongo-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Grant the EC2 instance permission to fetch both the admin and user secrets
resource "aws_iam_role_policy" "mongo_permissions" {
  name = "mongo-instance-permissions"
  role = aws_iam_role.mongo_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SecretsManagerReadAccess",
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = [
          aws_secretsmanager_secret.mongo_manager.arn,
          aws_secretsmanager_secret.mongo_user_secret.arn
        ]
      },
      {
        Sid    = "S3BackupWriteAccess",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "${aws_s3_bucket.mongodb-backup.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mongo_instance_profile" {
  name = "mongo-instance-profile"
  role = aws_iam_role.mongo_instance_role.name
}