resource "aws_lambda_function" "lambda_function" {
  for_each      = var.lambda_functions
  function_name = "${var.application_name}-${each.key}"
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size
  description   = each.value.description
  role          = aws_iam_role.lambda_role[each.key].arn

  ephemeral_storage {
    size = 512
  }
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    subnet_ids         = data.aws_subnets.routable-subnets.ids
    security_group_ids = aws_security_group.lambda_sg[each.key].id
  }
  logging_config {
    log_group  = "/aws/lambda/${var.application_name}-${each.key}"
    log_format = "JSON"
  }
}