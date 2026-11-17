resource "aws_api_gateway_rest_api" "main" {
  name        = "clops-api"
  description = "clops REST API"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    name = var.application_name
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.main.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "clops-stage"
}

resource "aws_api_gateway_method_settings" "method_setting" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"
  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

#--------------------------------------------------------
#api-subtree resources
#--------------------------------------------------------
resource "aws_api_gateway_resource" "api_subtree" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "clops"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.api_subtree.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "gateway_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_subtree.id
  http_method = aws_api_gateway_method.method.http_method
  type        = "AWS_PROXY"

  integration_http_method = "POST"
  timeout_milliseconds    = 29000
}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_subtree.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"     = false
    "method.response.header.X-My-Demo-Header" = false
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_subtree.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code
}

#--------------------------------------------------------
#authorizer resources
#--------------------------------------------------------

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowclopsAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_lambda_arn
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*"
}

resource "aws_api_gateway_authorizer" "main" {
  name                             = "okta_authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.main.id
  authorizer_uri                   = var.authorizer_lambda_arn
  authorizer_credentials           = aws_iam_role.apigw_auth_role.arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}