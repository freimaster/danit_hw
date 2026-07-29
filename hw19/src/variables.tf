variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to local SSH public key"
  type        = string
  default     = "/home/user-a/.ssh/aws-terraform-lab.pub"
}

variable "ssh_cidr" {
  description = "Public IP permitted to connect to public EC2 by SSH"
  type        = string
}
