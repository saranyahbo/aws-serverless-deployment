### API Gateway alarms
resource "aws_cloudwatch_metric_alarms" "5xx_erros" {
  for_each            = var.lambda_functions
  alarm_name          = "${var.application_name}-${each.key}-5xx-errors"
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
  alarm_name          = "${var.application_name}-${each.key}-4xx-errors"
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
  alarm_name          = "${var.application_name}-${each.key}-latency"
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
  alarm_name          = "${var.application_name}-${each.key}-request-count"
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

### Lambda function alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each            = var.lambda_functions
  alarm_name          = "${var.application_name}-${each.key}-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when ${var.application_name}-${each.key} returns one or more errors"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    FunctionName = "${var.application_name}-${each.key}"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each            = var.lambda_functions
  alarm_name          = "${var.application_name}-${each.key}-lambda-throttles"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when ${var.application_name}-${each.key} is throttled"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    FunctionName = "${var.application_name}-${each.key}"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each            = var.lambda_functions
  alarm_name          = "${var.application_name}-${each.key}-lambda-duration-p95"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p95"
  threshold           = each.value.timeout * 1000 * 0.8
  alarm_description   = "Alarm when p95 duration of ${var.application_name}-${each.key} exceeds 80 percent of its timeout"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    FunctionName = "${var.application_name}-${each.key}"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent_executions" {
  for_each            = var.lambda_functions
  alarm_name          = "${var.application_name}-${each.key}-lambda-concurrent-executions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  threshold           = 800
  alarm_description   = "Alarm when ${var.application_name}-${each.key} concurrent executions exceed 80 percent of 1000"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    FunctionName = "${var.application_name}-${each.key}"
  }
}

### DynamoDB alarms
resource "aws_cloudwatch_metric_alarm" "dynamodb_user_errors" {
  for_each            = var.dynamodb_tables
  alarm_name          = "${var.application_name}-${each.value.name-suffix}-dynamodb-user-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when ${var.application_name}-${each.value.name-suffix} has DynamoDB user errors"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    TableName = "${var.application_name}-${each.value.name-suffix}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_system_errors" {
  for_each            = var.dynamodb_tables
  alarm_name          = "${var.application_name}-${each.value.name-suffix}-dynamodb-system-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when ${var.application_name}-${each.value.name-suffix} has DynamoDB system errors"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    TableName = "${var.application_name}-${each.value.name-suffix}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttled_requests" {
  for_each            = var.dynamodb_tables
  alarm_name          = "${var.application_name}-${each.value.name-suffix}-dynamodb-throttled-requests"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when ${var.application_name}-${each.value.name-suffix} has throttled requests"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    TableName = "${var.application_name}-${each.value.name-suffix}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_consumed_read_capacity" {
  for_each            = var.dynamodb_tables
  alarm_name          = "${var.application_name}-${each.value.name-suffix}-dynamodb-consumed-read-capacity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10000
  alarm_description   = "Alarm when ${var.application_name}-${each.value.name-suffix} consumed read capacity units exceed 10000 in 5 minutes"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    TableName = "${var.application_name}-${each.value.name-suffix}"
  }
}

### CloudFront alarms
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_error_rate" {
  alarm_name          = "clops-cloudfront-5xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm when CloudFront 5xx error rate exceeds 1 percent"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DistributionId = aws_cloudfront_distribution.s3_distribution.id
    Region         = "Global"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_error_rate" {
  alarm_name          = "clops-cloudfront-4xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Alarm when CloudFront 4xx error rate exceeds 5 percent"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DistributionId = aws_cloudfront_distribution.s3_distribution.id
    Region         = "Global"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_origin_latency" {
  alarm_name          = "clops-cloudfront-origin-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "OriginLatency"
  namespace           = "AWS/CloudFront"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 3000
  alarm_description   = "Alarm when CloudFront p95 origin latency exceeds 3000 milliseconds"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DistributionId = aws_cloudfront_distribution.s3_distribution.id
    Region         = "Global"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_total_error_rate" {
  alarm_name          = "clops-cloudfront-total-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TotalErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "Alarm when CloudFront total error rate exceeds 2 percent"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DistributionId = aws_cloudfront_distribution.s3_distribution.id
    Region         = "Global"
  }
}

### S3 frontend alarms
resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  alarm_name          = "clops-s3-frontend-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm when the S3 frontend 4xx error rate exceeds 1 percent"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    BucketName = each.value.s3_bucket_name
    FilterId   = "EntireBucket"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_5xx_errors" {
  alarm_name          = "clops-s3-frontend-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm when the S3 frontend returns at least one 5xx error"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    BucketName = each.value.s3_bucket_name
    FilterId   = "EntireBucket"
  }
}

### SNS alarms
resource "aws_cloudwatch_metric_alarm" "sns_notifications_failed" {
  alarm_name          = "clops-sns-notifications-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when SNS fails to deliver a notification"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    TopicName = aws_sns_topic.user_updates.name
  }
}

resource "aws_cloudwatch_metric_alarm" "sns_notifications_filtered" {
  alarm_name          = "clops-sns-notifications-filtered"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsFilteredOut-API"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when SNS filters out a publish API notification"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    TopicName = aws_sns_topic.user_updates.name
  }
}

### ACM certificate alarm
resource "aws_cloudwatch_metric_alarm" "acm_certificate_days_to_expiry" {
  alarm_name          = "clops-acm-certificate-days-to-expiry"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = 86400
  statistic           = "Minimum"
  threshold           = 30
  alarm_description   = "Alarm when the ACM certificate has fewer than 30 days until expiration"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]
  dimensions = {
    CertificateArn = data.aws_acm_certificate.my_domain.arn
  }
}
