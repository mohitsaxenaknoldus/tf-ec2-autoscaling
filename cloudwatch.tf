resource "aws_cloudwatch_event_rule" "daily_refresh" {
  name                = "DailyRefreshRule"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_refresh.name
  target_id = "AutoScalingRefreshLambda"
  arn       = aws_lambda_function.auto_scaling_refresh.arn
}

resource "aws_cloudwatch_metric_alarm" "load_average_scale_up" {
  alarm_name          = "LoadAverageScaleUpAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "LoadAverage"
  namespace           = "CustomMetrics"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn, aws_sns_topic.scaling_events_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "load_average_scale_down" {
  alarm_name          = "LoadAverageScaleDownAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "LoadAverage"
  namespace           = "CustomMetrics"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn, aws_sns_topic.scaling_events_topic.arn]
}