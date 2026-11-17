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