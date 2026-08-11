variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.30.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  type        = string
  default     = "10.30.2.0/24"
}

variable "master_instance_type" {
  description = "GitLab EC2 instance type"
  type        = string
  default     = "m7i-flex.large"
}

variable "runner_instance_type" {
  description = "GitLab Runner EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/aws-terraform-lab.pub"
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH to GitLab server"
  type        = string
  default     = "0.0.0.0/0"
}
