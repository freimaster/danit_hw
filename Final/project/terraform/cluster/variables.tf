variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  type    = string
  default = "freimaster"
}

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "admin_cidrs" {
  description = "Public IPv4 CIDRs allowed to reach the EKS API (your workstation /32)."
  type        = list(string)
  validation {
    condition     = length(var.admin_cidrs) > 0 && alltrue([for cidr in var.admin_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "Specify at least one IPv4 CIDR, preferably your public IP/32; 0.0.0.0/0 is not allowed."
  }
}

variable "capacity_type" {
  description = "ON_DEMAND works with Free Tier eligible types; SPOT is optional on accounts that allow it."
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.capacity_type)
    error_message = "Use SPOT or ON_DEMAND."
  }
}

variable "instance_types" {
  description = "Free Tier eligible x86_64 types with enough RAM for Argo CD and the application."
  type        = list(string)
  default     = ["c7i-flex.large"]
}
