output "instance_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.web.public_ip
}
