terraform {
  cloud {
    organization = "ms-personal"
    workspaces {
      tags = ["ec2-autoscaling"]
    }
  }
}
