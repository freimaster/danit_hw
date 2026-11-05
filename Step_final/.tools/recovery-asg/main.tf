terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.21.0"
    }
  }
}
provider "aws" {
  region = "eu-central-1"
}
resource "aws_autoscaling_group" "failed" {
  name                = "eks-main-20261105104312199800000009-22d0d5a7-1b7a-54e8-7ee3-45968a79a7cc"
  min_size            = 0
  max_size            = 1
  desired_capacity    = 0
  force_delete        = true
  vpc_zone_identifier = ["subnet-030e3282af799702a"]
  launch_template {
    id      = "lt-026f0b0d5ef17cb9a"
    version = "1"
  }
}
