resource "aws_sns_topic" "user_updates" {
  name = "clops-sns-user-updates"
}

resource "aws_sns_topic_subscription" "user_updates_email" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "saranya.rathinasapapathi@gmail.com"
}