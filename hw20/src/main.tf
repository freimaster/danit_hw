resource "aws_vpc" "hw20" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hw20-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.hw20.id
  cidr_block              = "10.20.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "hw20-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hw20.id

  tags = {
    Name = "hw20-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hw20.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "hw20-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

module "web_server" {
  source = "./modules/web-server"

  vpc_id             = aws_vpc.hw20.id
  list_of_open_ports = var.list_of_open_ports

  depends_on = [
    aws_route_table_association.public
  ]
}
