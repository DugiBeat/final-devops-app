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
      echo "SSH is Ready!"
      echo "Running Ansible Playbook to install Jenkins Configurations..."
      ansible-playbook -i ${aws_eip.jenkins_eip.public_ip}, -u ubuntu --private-key ./keys/terraform-ec2-key.pem ./yamls/iConfigJenkins.yml
      echo "jenkins is ready!"
    EOT
  }
}

resource "null_resource" "iAnsible_ConfJenkins_Creds" {
  depends_on = [null_resource.iAnsible_ConfJenkins]

  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_SSH_ARGS="-o ServerAliveInterval=30 -o ServerAliveCountMax=60"
      echo "Waiting for SSH to be available..."
      until nc -z ${aws_eip.jenkins_eip.public_ip} 22; do sleep 5; done
      echo "SSH is Ready!"
      echo "Running Ansible Playbook to install Jenkins Configurations..."
      ansible-playbook -i ${aws_eip.jenkins_eip.public_ip}, -u ubuntu --private-key ./keys/terraform-ec2-key.pem ./yamls/iConfigJenCreds.yml
      echo "jenkins is ready!"
    EOT
  }
}


resource "null_resource" "iAnsible_ConfSQL" {
  depends_on = [null_resource.iAnsible_ConfJenkins_Creds]

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

