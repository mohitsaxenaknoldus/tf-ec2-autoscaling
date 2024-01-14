resource "aws_lambda_function" "auto_scaling_refresh" {
  function_name = "AutoScalingRefreshLambda"
  runtime       = "python3.8"
  handler       = "lambda_function.lambda_handler"
  filename      = "lambda/lambda_function.zip"
  role          = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      AUTO_SCALING_GROUP_NAME = aws_autoscaling_group.autoscaling_group.name
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_scaling_refresh.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_refresh.arn
}

resource "aws_lambda_function_event_invoke_config" "invoke_sns" {
  function_name = aws_lambda_function.auto_scaling_refresh.function_name
  destination_config {
    on_failure {
      destination = aws_sns_topic.scaling_events_topic.arn
    }
    on_success {
      destination = aws_sns_topic.scaling_events_topic.arn
    }
  }
}