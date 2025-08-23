# Final DevOps Project - Cyber WebApp 

This project is a fully integrated DevOps-driven Flask web application with a cybersecurity layer,
inspired by a foundational contact manager taught in class.
Built from the ground up on cloud infrastructure with modern deployment practices, it includes automation, monitoring, and scalability.

## 🚀 Complete DevOps Pipeline Demonstration

<div align="center">
  <a href="https://youtu.be/y2wSE54u35k">
    <img src="https://img.youtube.com/vi/y2wSE54u35k/maxresdefault.jpg" alt="DevOps Deployment Demo" width="600" style="border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
  </a>
  
  **🎬 Live Deployment Walkthrough**  
  *See the complete automation workflow from infrastructure provisioning to monitoring setup*
  
  [![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtu.be/y2wSE54u35k)
</div>


## 🚀 Project Overview

This extended version of the original course app includes:

- Contact Management system (original foundation)
- Cybersecurity enhancements:
  - Meeting booking system for cybersecurity consulting
  - Security alerts dashboard with live CVE feeds (via NVD API)
  - WHOIS/Crawler tool for domain inspection
- Responsive front-end with DevOps-inspired dark UI
- Full CI/CD pipeline using:
  - **Terraform** for infrastructure
  - **Ansible** for configuration
  - **Helm** for app deployment
  - **AWS EKS** as the Kubernetes orchestrator
  - **Jenkins** as the pipeline executor
  - **Prometheus + Grafana** for metrics and alerting

---

## 📁 Project Structure

```text
final-devops-app/
├── webapp/                               # Flask application with templates and static assets
│   ├── helm-chart/                       # Helm chart for deployment
│   ├── static/
│   ├── templates/
│   ├── .env                              # .env for local dockerization
│   ├── app.py
│   ├── data_mongo.py
│   ├── data_sql.py
│   ├── docker-compose.yml
│   ├── dockerfile
│   ├── migrate.py
│   ├── mongoDB.py
│   ├── requirements.txt
│   └── wait-for-mysql.sh                 # used via docker-compose file
│
├── terraform/                            # Terraform IaC modules and configs
│   ├── main.tf                           # core infrastructure
│   ├── setup_provisioners.tf             # Set & configure components after core infrastructure has been created
│   ├── ssh_key_management.tf             # Manages the lifecycle of SSH key pairs
│   ├── variables.tf
│   ├── output.tf
│   ├── install_packages.sh               # Shell script for Jenkins EC2 bootstrap
│   └── yamls/                            # Ansible playbooks
│       ├── iConfigJenkins.yml
│       └── iConfigSQL.yml
│
├── Jenkinsfile                           # Jenkins pipeline definition
├── AutoRun.sh                            # Automates the entire process
├── Cleanup.sh                            # Cleans up Terraform and AWS resources
├── interactive_ssh_connect.sh            # Provides an interactive way to establish an SSH connection
└── README.md - You are here...
```

## ⚙️ How It Works

1. **Terraform** provisions:
   - VPC, subnets, IAM roles
   - Jenkins EC2 instance with EIP
   - EKS cluster and node group
   - ECR registry for image storage

2. **Ansible** configures:
   - Jenkins server and plugins
   - GitHub credentials
   - MySQL installation and database setup for Flask app

3. **Jenkins** runs a CI/CD pipeline:
   - Builds and pushes Flask Docker image to ECR
   - Updates kubeconfig
   - Installs Prometheus + Grafana via Helm
   - Deploys the app via Helm

4. **Helm** manages deployments:
   - Grafana with Prometheus as data source
   - Flask application connected to ECR image

---

## 📊 Monitoring

Prometheus scrapes metrics from Jenkins, Node Exporter, and Alertmanager.

Grafana displays dashboards at `http://<grafana-lb-ip>:3000`

---

## 🧠 Requirements

- Terraform 1.5+
- Ansible
- AWS CLI + access
- Jenkins server on Ubuntu 20.04+
- Helm 3 (kubernetis jenkins plugin)
- Docker pipeline(jenkins need to be authenticated to ECR)

---

## 🙏 Contributors

- **[@Shashkist](https://github.com/Shashkist)** – Instructor and author of the original contact management app used in class
- **[@fullstackjava082023](https://github.com/fullstackjava082023)** – files of the original contact management app used in class 
  
---

## 📬 Contact

Dugma-app – Final DevOps Project student  
Email: [Dugibeat210@gmail.com]  
GitHub: [@DugiBeat](https://github.com/DugiBeat)
