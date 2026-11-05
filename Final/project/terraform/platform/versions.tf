terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.21.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}

data "terraform_remote_state" "cluster" {
  backend = "local"
  config = {
    path = "${path.module}/../cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "local"
  config = {
    path = "${path.module}/../dns/terraform.tfstate"
  }
}

locals {
  cluster     = data.terraform_remote_state.cluster.outputs
  dns         = data.terraform_remote_state.dns.outputs
  app_host    = "app.${local.dns.domain}"
  argocd_host = "argocd.${local.dns.domain}"
  zone_id     = local.dns.zone_id
}

provider "aws" {
  region = local.cluster.aws_region
  default_tags {
    tags = {
      Project   = local.cluster.cluster_name
      ManagedBy = "Terraform"
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster.cluster_ca)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster.cluster_name, "--region", local.cluster.aws_region]
    }
  }
}

provider "kubernetes" {
  host                   = local.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster.cluster_ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster.cluster_name, "--region", local.cluster.aws_region]
  }
}
