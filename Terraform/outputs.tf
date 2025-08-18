# Terraform Outputs
# ==============================
output "project_summary" {
  value = join("\n", [
    "VPC ID: ${module.vpc.vpc_id}",
    "Public Subnets: ${join(", ", module.vpc.public_subnets)}",
    "ECR Repo URL: ${aws_ecr_repository.webapp.repository_url}",
    "------------------------------------------------------------------",
    "EKS Cluster Name: ${module.eks.cluster_name}",
    "EKS Cluster Endpoint: ${module.eks.cluster_endpoint}",
    "Kubeconfig Cmd: aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}",
    "Kubeconfig Apply Auth Cmd: kubectl apply -f ${local_file.aws_auth_configmap.filename}",
    "Kubeconfig Clean Auth Cmd: kubectl delete configmap aws-auth -n kube-system",
    "------------------------------------------------------------------",
    "Jenkins Instance ID: ${aws_instance.jenkins_instance.id}",
    "Private ec2 Key Path: ${path.module}/terraform-ec2-key.pem",
    "Jenkins Security Group ID: ${aws_security_group.jenkins_sg.id}",
    "Jenkins Instance Profile: ${aws_iam_instance_profile.jenkins_instance_profile.name}",
    "Jenkins Role: ${aws_iam_role.jenkins_role.name}",
    "Jenkins Role ARN: ${aws_iam_role.jenkins_role.arn}",
    "Jenkins Public IP: ${aws_instance.jenkins_instance.public_ip}",
    "Jenkins Private IP: ${aws_instance.jenkins_instance.private_ip}",
    "Jenkins Elastic IP: ${aws_eip.jenkins_eip.public_ip}",
    "Jenkins Dashboard URL: http://${aws_eip.jenkins_eip.public_ip}:8080",
    "Jenkins Initial Password: ${trimspace(data.local_file.jenkins_password.content)}"
  ])
}
