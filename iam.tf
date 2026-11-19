#--------------------------------------------------------
#API Gateway
#--------------------------------------------------------

#IAM role for API Gateway to assume when invoking the Lambda function
resource "aws_iam_role" "apigw_auth_role" {
  name = "${var.application_name}-apigw-authorizer-role"

  assume_role_policy = jsonencode({
    version = "2012-10-17"
    statement = [
      {
        effect = "Allow"
        principal = {
          service = "apigateway.amazonaws.com"
        }
        action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "apigw_auth_policy" {
  name = "${var.application_name}-apigw-authorizer-policy"
  role = aws_iam_role.apigw_auth_role.id
  policy = jsonencode({
    version = "2012-10-17"
    statement = [
      {
        effect = "Allow"
        action = [
          "lambda:InvokeFunction"
        ]
        resource = var.authorizer_lambda_arn
      }
    ]
  })
}

#--------------------------------------------------------
#Lambda
#--------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  for_each = var.lambda_functions
  name     = "${each.value.function_name}-lambda-role"
  assume_role_policy = jsonencode({
    version = "2012-10-17"
    statement = [
      {
        effect = "Allow"
        principal = {
          service = "lambda.amazonaws.com"
        }
        action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  for_each = var.lambda_functions
  name     = "${each.value.function_name}-lambda-policy"
  role     = aws_iam_role.lambda_role[each.key].id
  policy   = templatefile("$path.module}/templates/lambda_role.tmpl")
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  for_each   = var.lambda_functions
  role       = aws_iam_role.lambda_role[each.key].name
  policy_arn = aws_iam_role_policy.lambda_policy[each.key].arn
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
      "${aws_s3_bucket.clops-s3-cloudfront.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.clops-s3-cloudfront.bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

###-----------SNS----------###
resource "aws_iam_role" "sns_lambda_role" {
  name = "${var.application_name}-sns-lambda-role"

  assume_role_policy = jsonencode({
    version = "2012-10-17"
    statement = [
      {
        effect = "Allow"
        principal = {
          service = "lambda.amazonaws.com"
        }
        action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sns_lambda_policy" {
  name = "${var.application_name}-sns-lambda-policy"
  role = aws_iam_role.sns_lambda_role.id
  policy = jsonencode({
    version = "2012-10-17"
    statement = [
      {
        effect = "Allow"
        action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:Receive",
          "sns:ListSubscriptionsByTopic"
        ]
        resource = "*"
      }    
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_lambda_policy_attachment" {
  role       = aws_iam_role.sns_lambda_role.name
  policy_arn = aws_iam_role_policy.sns_lambda_policy.arn
}

resource "aws_lambda_permission" "sns_lambda_permission" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function["sns_notification_function"].function_name
  principal     = "sns.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = aws_sns_topic.user_updates.arn
}