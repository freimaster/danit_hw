data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "hw21" {
  cidr_block           = "10.21.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hw21-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.hw21.id
  cidr_block              = "10.21.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "hw21-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hw21.id

  tags = {
    Name = "hw21-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hw21.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "hw21-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "hw21" {
  name        = "hw21-sg"
  description = "HW21 SSH and HTTP"
  vpc_id      = aws_vpc.hw21.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hw21-sg"
  }
}

resource "aws_instance" "web" {
  count = 2

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.hw21.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "hw21-web-${count.index + 1}"
  }

  depends_on = [
    aws_route_table_association.public
  ]
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"

  content = <<-EOF
    [web]
    web1 ansible_host=${aws_instance.web[0].public_ip}
    web2 ansible_host=${aws_instance.web[1].public_ip}

    [web:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${pathexpand("~/.ssh/aws-terraform-lab")}
  EOF
}
