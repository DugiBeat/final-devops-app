resource "null_resource" "instance_readiness" {
depends_on = [module.eks]
  provisioner "local-exec" {
    command = <<EOT
echo "Fetching the latest Public IP..."
ACTUAL_IP=$(aws ec2 describe-instances --instance-ids ${aws_instance.jenkins_instance.id} --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

echo "Testing SSH connectivity to $ACTUAL_IP..."
RETRIES=10
while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ./keys/terraform-ec2-key.pem ubuntu@$ACTUAL_IP "echo 'Instance is ready'"; do
  echo "SSH failed, checking instance status..."

  INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids ${aws_instance.jenkins_instance.id} --query 'Reservations[*].Instances[*].State.Name' --output text)
  echo "Instance state: $INSTANCE_STATE"

  if [ "$INSTANCE_STATE" != "running" ]; then
    echo "Instance is not running. Exiting..."
    exit 1
  fi

  echo "Retrying SSH connection in 10 seconds..."
  sleep 10
  RETRIES=$((RETRIES-1))
  if [ $RETRIES -eq 0 ]; then
    echo "SSH still not working after multiple attempts. Exiting..."
    exit 1
  fi
done

echo "Instance is updated & ready!" 
EOT
  }
}

resource "null_resource" "ec2Update" {
  depends_on = [null_resource.instance_readiness]

   connection {
    type        = "ssh"
    user        = "ubuntu"  
    private_key = file(var.private_key_path)
    host        = aws_eip.jenkins_eip.public_ip 
    timeout     = "3m" 
  }

   provisioner "file" {  
    source      = "install_packages.sh"
    destination = "/home/ubuntu/install_packages.sh"
  }

   provisioner "remote-exec" {
     inline = [
      "echo 'Installing Packages Now...'",
      "chmod +x /home/ubuntu/install_packages.sh",
      "sudo /home/ubuntu/install_packages.sh",
      "echo 'Waiting for system to be fully booted...'",
      "exit"
    ]
  }
}

resource "null_resource" "wait_for_ssh" {
  depends_on = [null_resource.ec2Update]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for SSH to be available..."
      while ! nc -z ${aws_eip.jenkins_eip.public_ip} 22; do sleep 5; done
      echo "SSH is ready!"
    EOT
  }
}

resource "null_resource" "iAnsible_ConfJenkins" {
  depends_on = [null_resource.wait_for_ssh]
  
  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_SSH_ARGS="-o ServerAliveInterval=30 -o ServerAliveCountMax=60"
      echo "Waiting for SSH to be available..."
      until nc -z ${aws_eip.jenkins_eip.public_ip} 22; do sleep 5; done
      echo "Running Ansible to configure Jenkins..."
      ansible-playbook -i ${aws_eip.jenkins_eip.public_ip}, -u ubuntu --private-key ./keys/terraform-ec2-key.pem ./yamls/iConfigJenkins.yml
    EOT
  }
}

resource "null_resource" "get_jenkins_password" {
  depends_on = [null_resource.iAnsible_ConfJenkins]

  provisioner "local-exec" {
    command = <<-EOT
      ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no ubuntu@${aws_eip.jenkins_eip.public_ip} \
      'sudo cat /var/lib/jenkins/secrets/initialAdminPassword' > keys/jenkins_password.txt
    EOT
  }

  triggers = {
    instance_id = aws_instance.jenkins_instance.id
  }
}

# Read the password from the file
data "local_file" "jenkins_password" {
  depends_on = [null_resource.get_jenkins_password]
  filename   = "${path.module}/keys/jenkins_password.txt"
}
resource "null_resource" "iAnsible_ConfSQL" {
  depends_on = [
    null_resource.iAnsible_ConfJenkins,
    null_resource.ec2Update
  ]

  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_SSH_ARGS="-o ServerAliveInterval=30 -o ServerAliveCountMax=60"
      echo "Waiting for SSH to be available..."
      until nc -z ${aws_eip.jenkins_eip.public_ip} 22; do sleep 5; done
      echo "SSH is Ready!"
      echo "Running Ansible Playbook to install MYSQL Configurations..."
      ansible-playbook -i ${aws_eip.jenkins_eip.public_ip}, -u ubuntu --private-key ./keys/terraform-ec2-key.pem ./yamls/iConfigSQL.yml
      echo "jenkins is ready!"
    EOT
  }
}

resource "local_file" "aws_auth_configmap" {
  depends_on = [
    null_resource.get_jenkins_password,
    null_resource.iAnsible_ConfSQL
  ]
  content = <<-EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_node_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: arn:aws:iam::423623847692:role/jenkins-role
      username: jenkins
      groups:
        - system:masters
EOT
  filename = "${path.module}/aws-auth-configmap.yaml"
}

resource "null_resource" "apply_aws_auth" {
  depends_on = [module.eks, local_file.aws_auth_configmap]

  provisioner "local-exec" {
    command = <<EOT
      echo "Applying aws-auth ConfigMap..."
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}
      kubectl apply -f ${local_file.aws_auth_configmap.filename}
    EOT
  }
}

