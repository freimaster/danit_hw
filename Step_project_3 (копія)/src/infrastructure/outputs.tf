output "gitlab_public_ip" {
  description = "Public IP of GitLab server"
  value       = aws_instance.gitlab.public_ip
}

output "gitlab_private_ip" {
  description = "Private IP of GitLab server"
  value       = aws_instance.gitlab.private_ip
}

output "runner_private_ip" {
  description = "Private IP of GitLab Runner"
  value       = aws_instance.runner.private_ip
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}
