data "archive_file" "lambda" {
  for_each    = var.lambda_functions
  type        = "zip"
  source_dir  = "${path.module}/lambdas/${each.key}"
  output_path = "${path.module}/.build/${each.key}.zip"
  excludes    = ["__pycache__", "*.pyc"]
}

resource "aws_lambda_function" "lambda_function" {
  for_each         = var.lambda_functions
  function_name    = "${var.application_name}-${each.key}"
  handler          = each.value.handler
  runtime          = each.value.runtime
  timeout          = each.value.timeout
  memory_size      = each.value.memory_size
  description      = each.value.description
  role             = aws_iam_role.lambda_role[each.key].arn
  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256

  environment {
    variables = merge(each.value.environment, each.key == "backend_function" ? {
      PRODUCTS_TABLE = aws_dynamodb_table.dynamodb-table["products"].name
      ORDERS_TABLE   = aws_dynamodb_table.dynamodb-table["orders"].name
      } : {}, each.key == "okta_auth" ? {
      OKTA_ISSUER        = var.okta_issuer
      OKTA_AUDIENCE      = var.okta_audience
      OKTA_CLIENT_ID     = var.okta_client_id
      OKTA_CLIENT_SECRET = var.okta_client_secret
    } : {})
  }

  depends_on = [aws_iam_role_policy.lambda_policy, aws_iam_role_policy.backend_dynamodb]

  ephemeral_storage {
    size = 512
  }
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    subnet_ids         = data.aws_subnets.routable-subnets.ids
    security_group_ids = [aws_security_group.lambda_sg[each.key].id]
  }
  logging_config {
    log_group  = "/aws/lambda/${var.application_name}-${each.key}"
    log_format = "JSON"
  }
}
