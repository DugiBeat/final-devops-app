terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
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
  ingress {
    from_port   = 9090  # Prometheus port
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port   = 9093  # Alertmanager port
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port   = 3000  # Grafana default port
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {
    from_port   = 9100  # Node Exporter port
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this in production
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
    protocol    = "0"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EKS Node Role (used by Worker Nodes)
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
       "Action": "sts:AssumeRole"
    }]
  })
}

# Attach Necessary Policies to Worker Node Role
resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

  depends_on = [aws_iam_role.eks_node_role]
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance-profile"
  role = aws_iam_role.eks_node_role.name_prefix
}
resource "aws_instance" "jenkins_instance" {
  ami             = var.ami_id
  instance_type   = var.jenkins_type
  key_name        = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = module.vpc.public_subnets[0] 
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name = "JenkinsMachine"
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
  depends_on = [aws_instance.jenkins_instance]
  instance_id   = aws_instance.jenkins_instance.id
  allocation_id = aws_eip.jenkins_eip.id
}

# EKS Setup
module "eks" {
  source                   = "terraform-aws-modules/eks/aws"
  cluster_name             = "eks_mause"
  cluster_version          = "1.31"
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  vpc_id                   = module.vpc.vpc_id
  iam_role_arn             = aws_iam_role.eks_node_role.arn
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups  = {
    terra-eks = {
      name         = "terra-eks"
      min_size     = 1
      max_size     = 2
      desired_size = 2
      instance_types = ["t3.small"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
  authentication_mode = "API_AND_CONFIG_MAP"

  depends_on = [aws_iam_role.eks_node_role]
}
