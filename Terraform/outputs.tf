
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "jenkins_public_ip" {
  description = "The public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_instance.public_ip
}

output "private_key_path" {
  value = "${path.module}/terraform-ec2-key.pem"
}

output "ecr_webapp_repo_url" {
  description = "WebApp ECR URL"
  value       = aws_ecr_repository.webapp.repository_url
}

output "kubeconfig_cmd" {
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
}

output "jenkins_dashboard_url" {
  value = "http://${aws_instance.jenkins_instance.public_ip}:8080"
}

data "external" "jenkins_password" {
  depends_on = [null_resource.ec2Update]

  program = ["bash", "-c", <<EOT
    PASS=$(ssh -o StrictHostKeyChecking=no -i ${var.private_key_path} ubuntu@${aws_instance.jenkins_instance.public_ip} "sudo cat /var/lib/jenkins/secrets/initialAdminPassword")
    python3 -c "import json; print(json.dumps({'password': '$PASS'}))"
  EOT
  ]
}

output "jenkins_admin_password" {
  value     = data.external.jenkins_password.result.password
}



