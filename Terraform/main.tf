terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"  
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2" 
  name   = var.vpc_name
  cidr   = "10.10.0.0/16"

  azs             = ["eu-north-1a", "eu-north-1b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]

  enable_dns_support     = true
  enable_dns_hostnames   = true
  enable_nat_gateway     = true
  single_nat_gateway     = true

  tags = {
    Name = "Default project vpc"
  }
}

resource "aws_ecr_repository" "webapp" {
  name                 = "dugma-webapp"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Prometheus port
  ingress {
    from_port   = 9090  
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
# Alertmanager port
  ingress {
    from_port   = 9093  
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
# Grafana default port
  ingress {
    from_port   = 3000  
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
# Node Exporter port
  ingress {
    from_port   = 9100  
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==============================
# EKS Node IAM Role 
# ==============================
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"  
    }]
  })
}

# Policies for worker nodes
resource "aws_iam_role_policy_attachment" "node_eks_access" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_access" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ==============================
# Jenkins IAM Role (with Inline Policy)
# ==============================
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}
resource "aws_iam_role_policy_attachment" "jenkins_ecr_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}
# Inline Policy for Jenkins
resource "aws_iam_role_policy" "jenkins_inline_policy" {
  name = "jenkins-inline-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR permissions (push/pull/manage)
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy",
          "ecr:SetRepositoryPolicy"
        ]
        Resource = "*"
      },

      # EKS cluster access
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion"
        ]
        Resource = "*"
      },

      # Optional EC2/ELB for LoadBalancer services
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_instance" "jenkins_instance" {
  ami             = var.ami_id
  instance_type   = var.jenkins_type
  key_name        = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = module.vpc.public_subnets[0] 
  iam_instance_profile   = aws_iam_instance_profile.jenkins_instance_profile.name  # ✅ updated

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "JenkinsMachine"
  }

  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }
}

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_instance.id
}

resource "aws_eip_association" "jenkins_eip_association" {
  instance_id   = aws_instance.jenkins_instance.id
  allocation_id = aws_eip.jenkins_eip.id

  depends_on = [aws_instance.jenkins_instance, aws_eip.jenkins_eip]
}

# EKS Setup
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "eks_mause"
  cluster_version = "1.31"
  
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  authentication_mode = "API_AND_CONFIG_MAP"

  eks_managed_node_groups = {
    terra-eks = {
      name         = "terra-eks"
      min_size     = 1
      max_size     = 2
      desired_size = 2
      instance_types = ["t3.small"]
      
      create_iam_role = false
      iam_role_arn    = aws_iam_role.eks_node_role.arn
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  depends_on = [aws_iam_role.eks_node_role]
}
