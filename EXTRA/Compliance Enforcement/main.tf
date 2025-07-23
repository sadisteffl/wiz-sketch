resource "aws_iam_role" "s3_remediation_lambda_role" {
  name = "s3-remediation-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_remediation_lambda_policy" {
  name        = "s3-remediation-lambda-policy"
  description = "Policy for the S3 remediation Lambda function"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = "ssm:StartAutomationExecution",
        Resource = "arn:aws:ssm:us-east-1:296062560614:automation-definition/S3-RemediatePublicBucket*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_remediation_lambda_policy_attachment" {
  role       = aws_iam_role.s3_remediation_lambda_role.name
  policy_arn = aws_iam_policy.s3_remediation_lambda_policy.arn
}


resource "aws_lambda_function" "s3_remediation_lambda" {
  filename      = "s3_remediation_lambda.zip"
  function_name = "s3-remediation-lambda"
  role          = aws_iam_role.s3_remediation_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("s3_remediation_lambda.zip")

  environment {
    variables = {
      SSM_DOCUMENT_NAME = aws_ssm_document.s3_remediation_document.name
    }
  }
}

resource "aws_cloudwatch_event_rule" "s3_public_bucket_rule" {
  name        = "s3-public-bucket-rule"
  description = "Rule to detect public S3 buckets"

  event_pattern = jsonencode({
    "source"      = ["aws.s3"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    "detail"      = {
      "eventSource" = ["s3.amazonaws.com"],
      "eventName"   = ["PutBucketAcl"]
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_remediation_lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_public_bucket_rule.name
  target_id = "s3-remediation-lambda"
  arn       = aws_lambda_function.s3_remediation_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_remediation_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_public_bucket_rule.arn
}


resource "aws_iam_role" "s3_remediation_ssm_role" {
  name = "s3-remediation-ssm-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_remediation_ssm_policy" {
  name        = "s3-remediation-ssm-policy"
  description = "Policy for the S3 remediation SSM document"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketAcl"
        ],
        Resource = "*" # Restrict this to specific buckets if needed
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_remediation_ssm_policy_attachment" {
  role       = aws_iam_role.s3_remediation_ssm_role.name
  policy_arn = aws_iam_policy.s3_remediation_ssm_policy.arn
}

resource "aws_ssm_document" "s3_remediation_document" {
  name          = "S3-RemediatePublicBucket"
  document_type = "Automation"
  content = jsonencode({
    "description" : "Remediates a public S3 bucket by setting Block Public Access and a private ACL.",
    "schemaVersion" : "0.3",
    "assumeRole" : aws_iam_role.s3_remediation_ssm_role.arn,
    "parameters" : {
      "BucketName" : {
        "type" : "String",
        "description" : "The name of the S3 bucket to remediate."
      }
    },
    "mainSteps" : [
      {
        "name" : "BlockPublicAccess",
        "action" : "aws:executeAwsApi",
        "inputs" : {
          "Service" : "s3",
          "Api" : "PutPublicAccessBlock",
          "Bucket" : "{{ BucketName }}",
          "PublicAccessBlockConfiguration" : {
            "BlockPublicAcls" : true,
            "IgnorePublicAcls" : true,
            "BlockPublicPolicy" : true,
            "RestrictPublicBuckets" : true
          }
        }
      },
      {
        "name" : "SetPrivateAcl",
        "action" : "aws:executeAwsApi",
        "inputs" : {
          "Service" : "s3",
          "Api" : "PutBucketAcl",
          "Bucket" : "{{ BucketName }}",
          "ACL" : "private"
        }
      }
    ]
  })
}