variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "list_of_open_ports" {
  description = "List of TCP ports opened from the Internet"
  type        = list(number)
}
