resource "aws_sns_topic" "user_updates" {
  name = "clops-sns-user-updates"
}

resource "aws_sns_topic_subscription" "user_updates_lambda" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_function["sns_notification_function"].arn

  depends_on = [aws_lambda_permission.sns_lambda_permission]
}

resource "aws_sns_topic_subscription" "user_updates_email" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "gmail.com" # Replace with the desired email address for notifications
}
