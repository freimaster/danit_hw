output "vpc_id" {
  value = aws_vpc.lab.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "public_ec2_public_ip" {
  value = aws_instance.public.public_ip
}

output "public_ec2_private_ip" {
  value = aws_instance.public.private_ip
}

output "private_ec2_private_ip" {
  value = aws_instance.private.private_ip
}

output "ssh_public_ec2" {
  value = "ssh -A -i ~/.ssh/aws-terraform-lab ubuntu@${aws_instance.public.public_ip}"
}

output "ssh_private_from_public" {
  value = "ssh ubuntu@${aws_instance.private.private_ip}"
}
