terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.21.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "domain" {
  type    = string
  default = "systemd.pp.ua"
}

variable "existing_zone_id" {
  description = "Existing public Route 53 zone ID, or null to create a project-owned zone."
  type        = string
  default     = null
}

resource "aws_route53_zone" "main" {
  count = var.existing_zone_id == null ? 1 : 0
  name  = var.domain
  tags = {
    Project   = "freimaster"
    ManagedBy = "Terraform"
  }
}

data "aws_route53_zone" "existing" {
  count   = var.existing_zone_id != null ? 1 : 0
  zone_id = var.existing_zone_id
}

output "zone_id" {
  value = var.existing_zone_id != null ? var.existing_zone_id : aws_route53_zone.main[0].zone_id
}

output "domain" {
  value = var.domain
}

output "name_servers" {
  value = var.existing_zone_id != null ? data.aws_route53_zone.existing[0].name_servers : aws_route53_zone.main[0].name_servers
}
