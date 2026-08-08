variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "list_of_open_ports" {
  description = "List of TCP ports opened from the Internet"
  type        = list(number)
}
