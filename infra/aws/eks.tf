# EKS Cluster
resource "aws_eks_cluster" "sue_eks" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version = "1.30"

  //making sure that the cluster has api and configmap as auth methods
  access_config {
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true //here i decided to assign manually the github-actions role to be the admin of the cluster
  }
  vpc_config {
    subnet_ids = [
      aws_subnet.sue-subnet-private-1.id,
      aws_subnet.sue-subnet-private-2.id,
      aws_subnet.sue-subnet-public-1.id,
      aws_subnet.sue-subnet-public-2.id
    ]
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
  tags = var.tags
}

# Security Group for EKS Control Plane
resource "aws_security_group" "eks_cluster_sg" {
  name = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS control plane"
  vpc_id = aws_vpc.sue-vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster-sg" })
}

# Security Group for Worker Nodes
resource "aws_security_group" "eks_nodes_sg" {
  name = "${var.cluster_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id = aws_vpc.sue-vpc.id

  ingress {
    description = "Allow control plane to communicate with nodes"
    from_port = 1025
    to_port = 65535
    protocol = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes-sg" })
}

# EKS Node Group (placed in private subnets)
resource "aws_eks_node_group" "sue_eks_nodes" {
  cluster_name = aws_eks_cluster.sue_eks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn = aws_iam_role.eks_node_role.arn
  subnet_ids = [
    aws_subnet.sue-subnet-private-1.id,
    aws_subnet.sue-subnet-private-2.id
  ]
  instance_types = ["r5.4xlarge"] //CPU based instance type, would be great to test it with GPU
  ami_type       = "AL2_x86_64"
  disk_size      = 50
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 4
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_read_only,
  ]
  tags = var.tags
}

# Outputs
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value = aws_eks_cluster.sue_eks.endpoint
}

output "cluster_certificate_authority" {
  description = "EKS cluster CA data"
  value = aws_eks_cluster.sue_eks.certificate_authority[0].data
  sensitive = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value = aws_eks_cluster.sue_eks.name
}
//this part is necessary because it creates a connection between the AWS IAM and the Kubernetes
//Since by default EKS creats a cluster from the IAM entity that creates it, that being the GitHub role I created
//So I had to manually attach our roles to the cluster so we could connect to it
# resource "kubernetes_config_map_v1_data" "aws_auth" {
#   metadata {
#     name = "aws-auth"
#     namespace = "kube-system"
#   }
#   data = {
#     mapUsers = yamlencode([
#       for user in var.cluster_admins : {
#         userarn = user.userarn
#         username = user.username
#         groups = ["system:masters"]
#       }
#     ])
#     mapRoles = yamlencode([{
#       rolearn = aws_iam_role.eks_node_role.arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups = ["system:bootstrappers", "system:nodes"]
#     },
#     {
#       rolearn  = "arn:aws:iam::442908905354:role/github-actions-role"  # ← add this
#       username = "github-actions"
#       groups   = ["system:masters"]
#     }
#     ])
#   }
#   force = true
# }

//new approach since the pipeline is failing since I changed the code
//with this code I am trying to ensure that all the team members can access the cluster

resource "aws_eks_access_entry" "admin_users" {
  for_each = { for user in var.cluster_admins : user.username => user }

  cluster_name = aws_eks_cluster.sue_eks.name
  principal_arn = each.value.userarn
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_users" {
  for_each = { for user in var.cluster_admins : user.username => user }

  cluster_name = aws_eks_cluster.sue_eks.name
  principal_arn = each.value.userarn
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.admin_users]
}