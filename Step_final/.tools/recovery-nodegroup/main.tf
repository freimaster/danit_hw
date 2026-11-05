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
resource "aws_eks_node_group" "failed" {
  cluster_name    = "freimaster"
  node_group_name = "main-20261105104312199800000009"
  node_role_arn   = "arn:aws:iam::896680309229:role/main-eks-node-group-20261105103452138100000005"
  subnet_ids     = ["subnet-030e3282af799702a"]
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }
}
