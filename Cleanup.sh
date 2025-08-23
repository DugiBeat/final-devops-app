#!/bin/bash

# Ensure root privileges
if [ "$EUID" -ne 0 ]; then
  echo "You are not running as root. Please run with sudo."
  exit 1
fi

say() {
  echo "$1" | pv -qL ${2:-15}
}

say "------------------------------------------------------"
say " Welcome to Dugma's Final DevOps Project Cleanup"
say "------------------------------------------------------"

cd Terraform/ || { echo "Terraform folder not found"; exit 1; }

set -e
CLUSTER_NAME="eks_mause"
REGION="eu-north-1"

echo "Cleaning up aws-auth ConfigMap before destroy..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
kubectl delete configmap aws-auth -n kube-system || true

echo "Destroying Terraform resources..."

# Run Terraform destroy
cleanup_terraform() {
  cd ./Terraform || { echo "Terraform folder not found"; exit 1; }

  say "Starting Terraform destroy..." 15
  terraform destroy -auto-approve

  if [ $? -eq 0 ]; then
    say "Terraform resources destroyed successfully."
  else
    say "Terraform destroy failed. Check errors and retry."
    exit 1
  fi

  cd ..
}

cleanup_terraform

# Ask if user wants to remove installed software
say "Do you want to remove installed software packages? (yes/no) [Warning!its will delete all info]" 15
read -r cleanup_software_response

# Default to 'no' if empty input
if [[ -z "$cleanup_software_response" ]]; then
  cleanup_software_response="no"
fi

if [[ "$cleanup_software_response" == "yes" ]]; then
  say "Removing installed software packages..." 15
  
  # Remove software in reverse order of installation
  SOFTWARE_TO_REMOVE=("terraform" "kubectl" "awscli" "openjdk-11-jdk" "pv")
  
  for software in "${SOFTWARE_TO_REMOVE[@]}"; do
    case $software in
    "terraform")
      say "Removing Terraform..."
      apt remove -y terraform
      rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
      rm -f /etc/apt/sources.list.d/hashicorp.list
      ;;
    "kubectl")
      say "Removing kubectl..."
      rm -f /usr/local/bin/kubectl
      ;;
    "awscli")
      say "Removing AWS CLI..."
      rm -rf /usr/local/aws-cli
      rm -f /usr/local/bin/aws
      rm -f /usr/local/bin/aws_completer
      rm -f awscliv2.zip
      rm -rf ./aws
      ;;
    "openjdk-11-jdk")
      say "Removing Java..."
      apt remove -y openjdk-11-jdk
      ;;
    "pv")
      say "Removing pv..."
      apt remove -y pv
      ;;
    esac
    say "$software removed."
  done
  
  # Clean up apt cache
  say "Cleaning up package cache..."
  apt autoremove -y
  apt autoclean
  
  say "Software cleanup completed."
else
  say "Skipping software removal."
fi

# Clean up summary file if exists
if [ -f "project-summary.txt" ]; then
  say "Removing project summary file..."
  rm -f project-summary.txt
  say "Summary file removed."
fi

say "------------------------------------------------------"
say " Cleanup completed successfully!" Thank you 
say "------------------------------------------------------"
