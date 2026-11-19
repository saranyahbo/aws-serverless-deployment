### API Gateway alarms
resource "aws_cloudwatch_metric_alarms" "5xx_erros" {
  for_each            = var.lambda_functions
  alarm_name          = "${each.value.function_name}-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alarm when API Gateway returns 5XX errors for ${each.value.function_name}"
  dimensions = {
    ApiName = each.value.function_name
  }
}

resource "aws_cloudwatch_metric_alarms" "4xx_errors" {
  for_each            = var.lambda_functions
  alarm_name          = "${each.value.function_name}-4xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alarm when API Gateway returns 4XX errors for ${each.value.function_name}"
  dimensions = {
    ApiName = each.value.function_name
  }
}

resource "aws_cloudwatch_metric_alarms" "latency" {
  for_each            = var.lambda_functions
  alarm_name          = "${each.value.function_name}-latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "Alarm when API Gateway latency exceeds 1000ms for ${each.value.function_name}"
  dimensions = {
    ApiName = each.value.function_name
  }
}

resource "aws_cloudwatch_metric_alarms" "request_count" {
  for_each            = var.lambda_functions
  alarm_name          = "${each.value.function_name}-request-count"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when API Gateway request count is less than or equal to 1 for ${each.value.function_name}"
  dimensions = {
    ApiName = each.value.function_name
  }
}

### lambda function alarms