#--------------------------------------------------------
#API Gateway
#--------------------------------------------------------

resource "aws_iam_role" "apigw_cloudwatch_logs" {
  name = "${var.application_name}-apigw-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch_logs" {
  role       = aws_iam_role.apigw_cloudwatch_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_logs.arn

  depends_on = [aws_iam_role_policy_attachment.apigw_cloudwatch_logs]
}

#IAM role for API Gateway to assume when invoking the Lambda function
resource "aws_iam_role" "apigw_auth_role" {
  name = "${var.application_name}-apigw-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "apigw_auth_policy" {
  name = "${var.application_name}-apigw-authorizer-policy"
  role = aws_iam_role.apigw_auth_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.lambda_function["okta_auth"].arn
      }
    ]
  })
}

#--------------------------------------------------------
#Lambda
#--------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  for_each = var.lambda_functions
  name     = "${var.application_name}-${each.key}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  for_each = var.lambda_functions
  name     = "${var.application_name}-${each.key}-lambda-policy"
  role     = aws_iam_role.lambda_role[each.key].id
  policy = templatefile("${path.module}/templates/lambda_role.tmpl", {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.region
  })
}

resource "aws_iam_role_policy" "backend_dynamodb" {
  name = "${var.application_name}-backend-dynamodb"
  role = aws_iam_role.lambda_role["backend_function"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:Scan", "dynamodb:PutItem"]
      Resource = [for table in aws_dynamodb_table.dynamodb-table : table.arn]
    }]
  })
}

###---------------------Cloudfront---------------------###

data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.main["cloudfront"].arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.main["cloudfront"].bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

###-----------SNS----------###
resource "aws_iam_role" "sns_lambda_role" {
  name = "${var.application_name}-sns-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sns_lambda_policy" {
  name = "${var.application_name}-sns-lambda-policy"
  role = aws_iam_role.sns_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:Receive",
          "sns:ListSubscriptionsByTopic"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "sns_lambda_permission" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function["sns_notification_function"].function_name
  principal     = "sns.amazonaws.com"

  source_arn = aws_sns_topic.user_updates.arn
}
