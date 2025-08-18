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
say " Welcome to Dugma’s(DugiBeat) Final DevOps Project Installer"
say "------------------------------------------------------"

# Required software
REQUIRED_SOFTWARE=("pv" "java" "ansible" "aws" "terraform" "kubectl")

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install requirements if missing
for software in "${REQUIRED_SOFTWARE[@]}"; do
  if ! command_exists "$software"; then
    say "$software not found. Installing..."
    case $software in
    "pv") apt update -y && apt install -y pv ;;
    "java") apt update -y && apt install -y openjdk-11-jdk ;;
    "kubectl")
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      ;;
    "aws")
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip && ./aws/install
      aws configure
      ;;
    "terraform")
      curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
      apt update -y && apt install -y terraform
      ;;
    esac
    say "$software installed successfully."
  else
    say "$software already installed."
  fi
done

say "All requirements are installed."

# Ask to continue with Terraform
say "Do you want to continue with Terraform deployment? (yes/no)" 15
read -r tf_response
if [[ "$tf_response" != "yes" ]]; then
  say "Exiting... you can run Terraform manually later."
  exit 0
fi

run_terraform() {
  cd ./Terraform || { echo "Terraform folder not found"; exit 1; }

  terraform init
  terraform validate
  terraform plan -out=tfplan
  terraform apply tfplan -auto-approve

  if [ $? -eq 0 ]; then
    say "Terraform execution completed successfully."
  else
    say "Terraform execution failed. Check errors and retry."
    exit 1
  fi

  cd ..

  # Create summary file
  SUMMARY="project-summary.txt"
  echo "================= Project Deployment Summary =================" > "$SUMMARY"

  # Jenkins info
  JENKINS_URL=$(terraform -chdir=./Terraform output -raw jenkins_dashboard_url)
  JENKINS_PASS=$(terraform -chdir=./Terraform output -raw jenkins_initial_password)
  echo "✅ Jenkins Dashboard: $JENKINS_URL" >> "$SUMMARY"
  echo "   Username: admin" >> "$SUMMARY"
  echo "   Password: $JENKINS_PASS" >> "$SUMMARY"
  echo "" >> "$SUMMARY"

  # Wait for Grafana/Flask LoadBalancer IPs
  say "Waiting for LoadBalancer IPs (Grafana/Flask)... this may take 2-3 minutes." 15
  for svc in grafana dugma-service; do
    for i in {1..30}; do
      LB_IP=$(kubectl get svc -A -o jsonpath="{.items[?(@.metadata.name=='$svc')].status.loadBalancer.ingress[0].hostname}" 2>/dev/null)
      if [[ -n "$LB_IP" ]]; then
        echo "✅ $svc: http://$LB_IP" >> "$SUMMARY"
        break
      else
        sleep 10
      fi
    done
  done

  # Get Grafana password
  GRAFANA_PASS=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode)
  if [[ -n "$GRAFANA_PASS" ]]; then
    echo "   Grafana Admin Password: $GRAFANA_PASS" >> "$SUMMARY"
  else
    echo "   Grafana Admin Password: (Run kubectl manually)" >> "$SUMMARY"
  fi

  echo "===============================================================" >> "$SUMMARY"

  say "Summary saved to $SUMMARY"
}

run_terraform

# Prompt for SSH into Jenkins
say "Do you want to SSH into Jenkins now? (yes/no)" 15
read -r ssh_response
if [[ "$ssh_response" == "yes" ]]; then
  if [ -f "./Ssh-connect.sh" ]; then
    bash ./Ssh-connect.sh
  else
    say "SSH script not found. Please connect manually."
  fi
else
  say "Setup complete. Goodbye!"
fi
