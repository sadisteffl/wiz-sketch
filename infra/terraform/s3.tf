resource "random_id" "suffix" {
  byte_length = 4
}


resource "aws_s3_bucket" "mongodb-backup" {
  bucket = "mongodb-backup-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "wiz-exercise-cloudtrail-logs-${random_id.suffix.hex}"
  force_destroy = true # Use with caution in production
  tags = {
    Name = "CloudTrail Logs"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs_block" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "db_backups_public_access" {
  bucket = aws_s3_bucket.mongodb-backup.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.mongodb-backup.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          aws_s3_bucket.mongodb-backup.arn,
          "${aws_s3_bucket.mongodb-backup.arn}/*"
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.db_backups_public_access]
}

resource "aws_s3_bucket" "config_logs" {
  bucket = "wiz-exercise-config-logs-${random_id.suffix.hex}"
}