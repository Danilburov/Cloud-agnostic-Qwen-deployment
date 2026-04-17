data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
    data.aws_availability_zones.available.names[2],
  ]

  # Public subnets — one per AZ
  # Used for load balancers only, nodes never go here
  public_subnets = [
    "10.0.2.0/24",   # AZ 3 — e.g. us-east-1c
  ]

  # Private subnets — one per AZ
  # All EKS nodes (CPU + GPU) live here
  private_subnets = [
    "10.0.12.0/24",  # AZ 3 — e.g. us-east-1c
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = true   # one NAT GW for all private subnets
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required for the AWS Load Balancer Controller
  # to know which subnets to place public-facing LBs in
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # Required for the AWS Load Balancer Controller
  # to know which subnets to place internal LBs in
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}
