## Terraform module for AWS ASG

This module will create all the necessary resources required for AWS ASG.

### How To Run?

```terraform
terraform init
terraform plan -out PLAN
terraform apply PLAN
```

### Custom Metric-Based Autoscaling

Since there is no inbuilt metric for load average, each EC2 instance in the group will push its load average to the custom CloudWatch metric.

There is a custom user-data script that installs `awscli` in the machines and sets up a cron job that pushes the metric data after every 5 minutes.

```shell
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
```

The Kernel level load average is derived through the `uptime` command and filtered using `awk`.

The autoscaling rules read this metric and based on the value scales the VMs up/down.

### Autoscaling Group Refresh

Refresh functionality is implemented through a custom Lambda function that triggers the refresh functionality of the ASG using `awscli`.

```python
import os
import boto3

def lambda_handler(event, context):
    auto_scaling_group_name = os.environ['AUTO_SCALING_GROUP_NAME']

    client = boto3.client('autoscaling')
    response = client.start_instance_refresh(
        AutoScalingGroupName=auto_scaling_group_name,
        Strategy='Rolling',
        Preferences={
            'MinHealthyPercentage': 90
        }
    )
    return response

```

The ASG name is passed as an environment variable.

This Lambda is triggered every day at 12 AM UTC through the CloudWatch event rule.

### Email Notifications

Email notifications are triggered through AWS SNS during both scaling and refreshes.

### Remote Backend

This module uses Terraform Cloud as the remote backend.

```terraform
terraform {
  cloud {
    organization = "ms-personal"
    workspaces {
      tags = ["ec2-autoscaling"]
    }
  }
}

```