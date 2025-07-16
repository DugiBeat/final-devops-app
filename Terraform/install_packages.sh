#!/bin/bash

# Function to check if the previous command was successful
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "\e[32m[SUCCESS]\e[0m $1"
    else
        echo -e "\e[31m[ERROR]\e[0m $1"
        exit 1
    fi
}

echo "------------------------------"
echo "Updating package list ..."
sudo apt update -y
check_success "Package list updated."

echo "------------------------------"
echo "Upgrading packages ..."
sudo apt upgrade -y --fix-missing
check_success "System upgraded."

echo "------------------------------"
echo "Installing unzip ..."
sudo apt install unzip -y
check_success "Unzip installed."

echo "------------------------------"
echo "Installing AWS CLI v2 ..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
check_success "AWS CLI installed."

echo "------------------------------"
echo "Installing kubectl ..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
check_success "Kubectl installed."

echo "------------------------------"
echo "Installing required dependencies ..."
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates
check_success "Dependencies installed."

echo "------------------------------"
echo "Installing OpenJDK 17 ..."
sudo apt install -y openjdk-17-jdk
check_success "OpenJDK 17 installed."

echo "------------------------------"
echo "Installing Python 3 & virtualenv ..."
sudo apt install -y python3 python3.12-venv python3-pip
check_success "Python 3 & venv installed."

echo "------------------------------"
echo "Creating Python virtual environment ..."
python3 -m venv /home/ubuntu/venv
echo 'source /home/ubuntu/venv/bin/activate' >> ~/.bashrc
check_success "Virtual environment setup."

echo "------------------------------"
echo "Adding Jenkins repository key ..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
check_success "Jenkins GPG key added."

echo "Adding Jenkins repository to sources.list ..."
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
check_success "Jenkins repo added."

echo "------------------------------"
echo "Updating package list again ..."
sudo apt update -y
check_success "Packages refreshed."

echo "Installing Jenkins ..."
sudo apt install -y jenkins
check_success "Jenkins installed."

echo "Starting Jenkins service ..."
sudo systemctl start jenkins
sudo systemctl enable jenkins
systemctl is-active --quiet jenkins && check_success "Jenkins is running." || { echo "[ERROR] Jenkins failed to start!"; exit 1; }

echo "------------------------------"
echo "Installing Docker (Ubuntu-safe) ..."

# Remove older versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Set up Docker repository
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
check_success "Docker installed."

# Add both ubuntu and jenkins users to docker group
echo "Adding ubuntu and jenkins users to docker group ..."
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
sudo systemctl enable docker
sudo systemctl restart docker
docker --version
check_success "Docker ready."

echo "------------------------------"
echo "Installing Helm ..."
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  check_success "Helm installed."
else
  echo "Helm already installed."
fi

echo "------------------------------"
echo "All packages installed and services configured successfully."
sleep 5
exit 0
