resource "aws_launch_configuration" "launch_config" {
  name_prefix          = "launch_config"
  image_id             = var.image_id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  security_groups      = [aws_security_group.instance_sg.id]
  user_data            = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y awscli
              sudo bash -c 'cat <<CUSTOM_SCRIPT > /tmp/publish_load_average.sh
              #!/bin/bash
              load_average=\$(uptime | awk -F"[a-z]:" "{ print \\\$2 }" | awk -F, "{ print \\\$3 }" | awk -F. "{ print \\\$1 }")
              aws cloudwatch put-metric-data \\
                --region us-east-1 \\
                --metric-name LoadAverage \\
                --namespace CustomMetrics \\
                --dimensions InstanceId=\$(curl -s http://169.254.169.254/latest/meta-data/instance-id) \\
                --value \$load_average
              CUSTOM_SCRIPT'
              sudo chmod +x /tmp/publish_load_average.sh
              (crontab -l 2>/dev/null; echo "*/5 * * * * /bin/bash /tmp/publish_load_average.sh") | crontab -
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  vpc_zone_identifier       = [var.subnet_id]
  launch_configuration      = aws_launch_configuration.launch_config.id
  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  cooldown               = 300
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  cooldown               = 300
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Security group allowing all traffic"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
