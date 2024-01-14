resource "aws_iam_policy" "auto_scaling_refresh_policy" {
  name        = "AutoScalingRefreshPolicy"
  description = "IAM policy for Auto Scaling Refresh Lambda function"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:StartInstanceRefresh"
        ],
        Resource = aws_autoscaling_group.autoscaling_group.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "auto_scaling_refresh_policy_attachment" {
  policy_arn = aws_iam_policy.auto_scaling_refresh_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role" "lambda_exec" {
  name = "Lambda_Execution_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_exec" {
  name       = "Lambda_Execution_Policy_Attachment"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "instance_role" {
  name               = "instance-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "cloudwatch-policy"
  description = "IAM policy for CloudWatch metrics"
  policy      = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "cloudwatch:PutMetricData",
      "Resource": "*"
    }
  ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_iam_policy" "lambda_sns_publish_policy" {
  name        = "lambda_sns_publish_policy"
  description = "IAM policy for Lambda to publish to SNS"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.scaling_events_topic.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_sns_publish_attachment" {
  policy_arn = aws_iam_policy.lambda_sns_publish_policy.arn
  role       = aws_iam_role.lambda_exec.name
}