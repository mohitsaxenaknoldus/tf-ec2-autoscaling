resource "aws_sns_topic" "scaling_events_topic" {
  name = "scaling_events_topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.scaling_events_topic.arn
  protocol  = "email"
  endpoint  = var.email
}