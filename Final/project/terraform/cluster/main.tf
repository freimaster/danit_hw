data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.cluster_name }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.8"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  upgrade_policy     = { support_type = "STANDARD" }

  endpoint_public_access                   = true
  endpoint_private_access                  = true
  endpoint_public_access_cidrs             = var.admin_cidrs
  enable_cluster_creator_admin_permissions = true

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  enabled_log_types           = []
  create_cloudwatch_log_group = false
  enable_irsa                 = false
  create_kms_key              = false
  encryption_config           = null

  addons = {
    vpc-cni = {
      before_compute = true
    }
    kube-proxy = {}
    coredns = {
      configuration_values = jsonencode({ replicaCount = 1 })
    }
  }

  eks_managed_node_groups = {
    main = {
      subnet_ids     = [aws_route_table_association.public[0].subnet_id]
      instance_types = var.instance_types
      capacity_type  = var.capacity_type
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      update_config  = { max_unavailable = 1 }
    }
  }
}
