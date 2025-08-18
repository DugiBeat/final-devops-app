variable "region" {
  default = "eu-north-1"
}

variable "vpc_name" {
  default = "Dugivpc"
}

variable "cluster_name" {
  default = "eks_mause"
}

variable "jenkins_type" {
  default = "t3.small"
}

variable "ami_id" {
  default = "ami-075449515af5df0d1"
}

variable "private_key_path" {
  default = "./keys/terraform-ec2-key.pem"
}
