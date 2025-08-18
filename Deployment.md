# 🚀 DEPLOYMENT GUIDE
**Complete Deployment Instructions for Dugma DevOps Project**

> *Step-by-step deployment guide for the Flask Cybersecurity Dashboard with full CI/CD automation pipeline.*

---

## 📋 **Quick Reference**

For complete project information, features, and overview, see the main [README.md](./README.md).

This deployment guide covers:
- 🚀 **4 Deployment Methods** (Automated, Manual, Local, Docker)
- ⚙️ **Prerequisites & Setup**  
- 🔧 **Configuration Options**
- 📊 **Monitoring & Access**
- 🛠️ **Troubleshooting**
- 🧹 **Cleanup Procedures**

---

## 📁 **Deployment Structure Reference**

```
final-devops-app/
├── webapp/                          # Flask Application
│   ├── helm-chart/                  # Kubernetes Helm Chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       └── configmap.yaml
│   ├── static/                      # CSS, JS, Images
│   │   ├── images/
│   │   ├── js/
│   │   │   ├── index.js
│   │   │   └── index2.js
│   │   └── styles/
│   │       ├── styles1.css
│   │       └── styles2.css
│   ├── templates/                   # HTML Templates
│   │   ├── base.html
│   │   ├── index.html
│   │   ├── addContactForm.html
│   │   └── editContactForm.html
│   ├── app.py                       # Main Flask Application
│   ├── data_sql.py                  # MySQL Database Layer
│   ├── data_mongo.py                # MongoDB Database Layer
│   ├── mongoDB.py                   # MongoDB Connection
│   ├── migrate.py                   # Database Migration
│   ├── requirements.txt             # Python Dependencies
│   ├── dockerfile                   # Container Configuration
│   ├── docker-compose.yml           # Local Development
│   ├── .env                         # Environment Variables
│   └── wait-for-mysql.sh           # Database Startup Script
│
├── terraform/                       # Infrastructure as Code
│   ├── main.tf                      # Core AWS Infrastructure
│   ├── setup_provisioners.tf       # Post-deployment Config
│   ├── ssh_key_management.tf       # SSH Key Lifecycle
│   ├── variables.tf                # Input Variables
│   ├── output.tf                   # Output Values
│   ├── install_packages.sh         # Jenkins Bootstrap Script
│   └── yamls/                      # Ansible Playbooks
│       ├── iConfigJenkins.yml      # Jenkins Configuration
│       └── iConfigSQL.yml          # MySQL Configuration
│
├── Jenkinsfile                     # CI/CD Pipeline Definition
├── AutoRun.sh                      # Complete Automation Script
├── Cleanup.sh                      # Infrastructure Teardown
├── interactive_ssh_connect.sh     # SSH Access Helper
└── README.md                       # Project Documentation
```

---

## 🎯 **Deployment Methods Overview**

Choose the deployment method that fits your needs:

| Method | Use Case | Time | Complexity |
|--------|----------|------|------------|
| **🤖 Automated** | Production deployment | ~15 mins | ⭐ Easy |
| **🔧 Manual** | Learning/Understanding | ~30 mins | ⭐⭐⭐ Advanced |
| **💻 Local** | Development/Testing | ~5 mins | ⭐⭐ Moderate |
| **🐳 Docker** | Containerized testing | ~3 mins | ⭐⭐ Moderate |

---

## 🚀 **Deployment Options**

## **Option 1: Complete Automated Deployment (Recommended)**

### **Prerequisites**
```bash
# Required Tools
- Terraform 1.5+
- Ansible 2.9+
- AWS CLI configured with appropriate permissions
- kubectl
- Helm 3.x
```

### **🎯 One-Command Deployment**
```bash
# Clone the repository
git clone https://github.com/DugiBeat/final-devops-app.git
cd final-devops-app

# Run complete automation
chmod +x AutoRun.sh
./AutoRun.sh
```

**What `AutoRun.sh` Does:**
1. ✅ **Terraform Apply** - Creates AWS infrastructure (VPC, EKS, EC2+EIP, ECR)
2. ✅ **Ansible Configuration** - Configures Jenkins server and MySQL database  
3. ✅ **Jenkins Pipeline** - Triggers automated CI/CD pipeline
4. ✅ **Container Build** - Builds and pushes Docker image to ECR
5. ✅ **Kubernetes Deploy** - Deploys app via Helm charts to EKS
6. ✅ **Monitoring Setup** - Deploys Prometheus + Grafana monitoring stack

---

## **Option 2: Manual Step-by-Step Deployment**

### **Step 1: Infrastructure Provisioning**
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

**Creates:**
- 🏠 VPC with public/private subnets
- 🖥️ Jenkins EC2 instance with Elastic IP
- ☸️ EKS cluster with managed node groups
- 📦 ECR private registry
- 🔐 IAM roles and security groups

### **Step 2: Configuration Management**
```bash
# Configure Jenkins server
ansible-playbook -i inventory yamls/iConfigJenkins.yml

# Configure MySQL database  
ansible-playbook -i inventory yamls/iConfigSQL.yml
```

### **Step 3: Access Jenkins & Trigger Pipeline**
```bash
# Get Jenkins IP
terraform output jenkins_public_ip

# Access Jenkins at: http://<jenkins-ip>:8080
# Pipeline automatically triggers on GitHub push or manual execution
```

### **Step 4: Monitor Deployment**
```bash
# Check EKS cluster status
kubectl get nodes
kubectl get pods -n default

# Get application access points
kubectl get svc
```

---

## **Option 3: Local Development**

### **Prerequisites**
```bash
# Required
- Python 3.8+
- MySQL or MongoDB
- Virtual environment (recommended)
```

### **Setup & Run Locally**
```bash
# Clone and setup
git clone https://github.com/DugiBeat/final-devops-app.git
cd final-devops-app/webapp

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt
```

### **Configure Environment**
Create `.env` file in `/webapp` directory:
```bash
DATABASE_TYPE=MYSQL          # or MONGO
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=admin
DB_NAME=contacts_app
OPENAI_API_KEY=your-key-if-needed
```

### **Start Database**
```bash
# MySQL Option
sudo systemctl start mysql
# OR with Docker
docker run --name mysql -e MYSQL_ROOT_PASSWORD=admin -p 3306:3306 -d mysql:8.0

# MongoDB Option  
docker run -d -p 27017:27017 --name mongo mongo:latest
```

### **Run Application**
```bash
cd webapp
python app.py
# Access at: http://localhost:5052
```

---

## **Option 4: Docker Containerization**

### **Build & Run with Docker**
```bash
cd webapp

# Build Docker image
docker build -t dugma-app:latest .

# Run container
docker run -p 5052:5052 --env-file .env dugma-app:latest
```

### **Docker Compose (Full Stack)**
```bash
# Run with database
docker-compose up -d

# Access application
curl http://localhost:5052
```

---

## 📊 **Monitoring & Access Points**

After deployment, access your services:

### **🌐 Application Access**
- **Flask App**: `http://<load-balancer-ip>`
- **API Endpoints**: `http://<load-balancer-ip>/api/`

### **🔧 DevOps Tools**  
- **Jenkins CI/CD**: `http://<jenkins-eip>:8080`
- **Grafana Dashboards**: `http://<grafana-lb-ip>:3000`
- **Prometheus Metrics**: `http://<prometheus-lb-ip>:9090`

### **🔍 Get Service IPs**
```bash
# Get all service endpoints
kubectl get svc --all-namespaces

# Get Load Balancer IPs
kubectl get svc -o wide

# Get Jenkins IP
terraform output jenkins_public_ip
```

---

## 🛠️ **Management Commands**

### **SSH Access to Jenkins**
```bash
# Interactive SSH connection
./interactive_ssh_connect.sh

# Manual SSH
ssh -i ~/.ssh/terraform-key ec2-user@<jenkins-eip>
```

### **Scale Application**
```bash
# Scale Flask app pods
kubectl scale deployment dugma-deployment --replicas=3

# Check scaling status
kubectl get deployment dugma-deployment
```

### **View Logs**
```bash
# Application logs
kubectl logs -f deployment/dugma-deployment

# Jenkins pipeline logs (via Jenkins UI)
# Prometheus/Grafana logs
kubectl logs -f deployment/prometheus-server
kubectl logs -f deployment/grafana
```

### **Update Application**
```bash
# Push code changes to GitHub
git add . && git commit -m "Update" && git push

# Jenkins pipeline automatically:
# 1. Builds new Docker image
# 2. Pushes to ECR
# 3. Updates Kubernetes deployment
# 4. Performs rolling update
```

---

## 🧹 **Cleanup & Teardown**

### **Complete Infrastructure Cleanup**
```bash
# Remove all AWS resources
./Cleanup.sh

# Manual cleanup if needed
# 1. delete aws-auth from kubectl 
kubectl delete configmap aws-auth -n kube-system
# 2.terrafom destroy action
terraform destroy -auto-approve
```

### **Partial Cleanup**
```bash
# Remove only Kubernetes deployments
helm uninstall dugma-devops
kubectl delete all --all

# Keep infrastructure running
```

---

## 🔧 **Troubleshooting**

### **Common Issues & Solutions**

**🚨 Jenkins Pipeline Fails**
```bash
# Check Jenkins logs
ssh -i ~/.ssh/terraform-key ec2-user@<jenkins-ip>
sudo journalctl -u jenkins -f

# Verify ECR authentication
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
```

**🚨 EKS Connection Issues**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region us-west-2

# Check cluster status
kubectl cluster-info
```

**🚨 Database Connection Errors**
```bash
# Check MySQL status in Kubernetes
kubectl get pods | grep mysql
kubectl logs <mysql-pod-name>

# Port forward for debugging
kubectl port-forward svc/mysql 3306:3306
```

**🚨 Application Not Accessible**
```bash
# Check Load Balancer status
kubectl get svc dugma-service
kubectl describe svc dugma-service

# Check pod status
kubectl get pods
kubectl describe pod <pod-name>
```

---

## 📈 **Monitoring & Alerting**

### **Grafana Dashboards**
1. **Application Metrics**: Request rates, response times, error rates
2. **Infrastructure Metrics**: CPU, memory, disk usage
3. **Kubernetes Metrics**: Pod status, resource utilization
4. **Jenkins Metrics**: Build success rates, pipeline durations

### **Prometheus Alerts**
- High error rates (>5%)
- Pod restart loops
- High memory usage (>80%)
- Database connection failures

### **Custom Metrics**
The Flask application exposes custom metrics:
- Contact creation rate
- WHOIS scan frequency  
- CVE alert generation
- Meeting booking trends

---

## 🎯 **Project Learning Outcomes**

This project demonstrates proficiency in:

✅ **Infrastructure as Code** (Terraform)
✅ **Configuration Management** (Ansible)  
✅ **Continuous Integration/Deployment** (Jenkins)
✅ **Containerization** (Docker + ECR)
✅ **Container Orchestration** (Kubernetes + EKS)
✅ **Package Management** (Helm Charts)
✅ **Monitoring & Observability** (Prometheus + Grafana)
✅ **Cloud Architecture** (AWS Services)
✅ **Security Implementation** (IAM, Security Groups, VPC)
✅ **Full-Stack Development** (Flask + Database + Frontend)

---

## 🤝 **Contributing**

For contributions or issues:
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📧 **Contact & Support**

**Developer**: Dugma-app Final DevOps Project Student  
**Email**: [Dugibeat210@gmail.com](mailto:Dugibeat210@gmail.com)  
**GitHub**: [@DugiBeat](https://github.com/DugiBeat)  
**Repository**: [final-devops-app](https://github.com/DugiBeat/final-devops-app)

---

*🎓 This project represents a comprehensive implementation of modern DevOps practices with security-focused application development, suitable for production environments and continuous learning.*