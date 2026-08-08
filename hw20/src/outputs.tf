output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = module.web_server.instance_public_ip
}

output "nginx_url" {
  description = "Nginx URL"
  value       = "http://${module.web_server.instance_public_ip}"
}

output "vpc_id" {
  description = "Created VPC ID"
  value       = aws_vpc.hw20.id
}
