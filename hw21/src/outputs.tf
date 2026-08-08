output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}

output "inventory_file" {
  value = local_file.ansible_inventory.filename
}
