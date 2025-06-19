# Dugma FINAL DevOps PROJECT
- This app is a simple Cyber Dashboard Project to implement Ci (DevSecOps Project)
- The App Made from scratches for final submission in Devops Course.

⚠️ Disclaimer
  🏷️ This Project is a basic app for cybersecurity enthusiasts.

    📌 IM not responsible for the incorrect use of this app.

    📌 i recommend using this app for testing, learning and fun :D

# 🧩 Dugma App Structure:
- The Structure of the app:
- ├── app.py
- ├── data_sql.py
- ├── data_mongo.py
- ├── migrate.py
- ├── mongoDB.py
- ├── requirements.txt
- ├── README.md
- ├── templates/
- │   ├── base.html
- │   ├── index.html
- │   ├── addContactForm.html
- │   └── editContactForm.html
- ├── static/
- │   ├── images/
- │   │   └── (app images...)
- │   ├── js/
- │   │   ├── index.js
- │   │   └── index2.js
- │   └── styles/
- │       ├── styles1.css
- │       └── styles2.css 
## 🌟 Features in th app
- Contact Management (MySQL/MongoDB)
- Cybersecurity Domain Scanner (WHOIS)
- Cybersecurity Expert Meeting Booking System
- Security Alert Dashboard (NIST CVE Feed)
- CI/CD ready for Jenkins → Kubernetes

# 🛠️ Walkthrough Installation
- This guide will walk you through:
- All features in the app (with usage flow)
- How to run the project locally (MySQL or MongoDB backend)
- How to containerize the app
- How to deploy it with Helm to Kubernetes

# 🖥️ 𝟙. Running the Project Locally 
  Prerequisites:
  - Python 3.8+ 
  - Pip
  - MySQL or MongoDB installed (or Dockerized version)
  - Virtualenv (recommended)

 ## Clone the Repo and Set Up
```bash
    git clone https://github.com/your-username/dugma-devops-project.git
    cd dugma-devops-project
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
```

## Configure Environment
 Create a .env file:
```bash
    DATABASE_TYPE=MYSQL  # or MONGO
    DB_HOST=localhost
    DB_PORT=3306
    DB_USER=root
    DB_PASSWORD=admin
    DB_NAME=contacts_app
    OPENAI_API_KEY=your-key-if-needed
```
## Start Your Database
MySQL:
```bash
sudo systemctl start mysql
# OR with Docker:
docker run --name mysql -e MYSQL_ROOT_PASSWORD=admin -p 3306:3306 -d mysql
```
MongoDB:
```bash
docker run -d -p 27017:27017 --name mongo mongo
4️⃣ Run the Flask App
bash
Copy
Edit
python app.py
Go to: http://localhost:5052
```

# 🐳 𝟚. Dockerizing the App (Optional Step Before Helm)
## Dockerfile
```bash
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```
## Build & Run:
```bash
docker build -t dugma-app .
docker run -p 5052:5052 --env-file .env dugma-app
```
# ☸️ Part Ǝ: Deploying with Helm (Kubernetes)
## File Structure:
pgsql
Copy
Edit
helm-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
## Chart.yaml
```
apiVersion: v2
name: dugma-devops
version: 0.1.0
```
## Values.yaml
```
image:
  repository: dugma-app
  tag: latest
service:
  type: ClusterIP
  port: 5052

env:
  DATABASE_TYPE: MYSQL
  DB_USER: root
  DB_PASSWORD: admin
  DB_NAME: contacts_app
  DB_HOST: mysql
```
## deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dugma-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dugma
  template:
    metadata:
      labels:
        app: dugma
    spec:
      containers:
        - name: dugma-container
          image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
          ports:
            - containerPort: 5052
          env:
            - name: DATABASE_TYPE
              value: "{{ .Values.env.DATABASE_TYPE }}"
            - name: DB_USER
              value: "{{ .Values.env.DB_USER }}"
            - name: DB_PASSWORD
              value: "{{ .Values.env.DB_PASSWORD }}"
            - name: DB_NAME
              value: "{{ .Values.env.DB_NAME }}"
            - name: DB_HOST
              value: "{{ .Values.env.DB_HOST }}"
```
## Deploy with Helm
```bash
# Package app and push Docker image
docker build -t your-dockerhub/dugma-app:latest .
docker push your-dockerhub/dugma-app:latest

# Install Helm chart
cd helm-chart
helm install dugma-devops .
```
✅ Final Checks & Notes
- Use kubectl get svc to get the app’s external IP
- Ensure the DB is either deployed as another service in Kubernetes or hosted externally
- You can scale the app: kubectl scale deployment dugma-deployment --replicas=3

# 🔍🗺️ Extra: Features This App Has & Where to Find Them
- This app is a simple Cyber DevOps Dashboard that includes:

✅ 1. Contact Management
  - Add Contact (/addContact)
  - Edit Contact (/editContact/<id>)
  - View All Contacts (/viewContacts)
  - Search Contacts via name (search bar in navbar)
  
  Stored in MySQL or MongoDB (switch via .env)


✅ 2. Crawler App (Passive OSINT Tool)
  - POST /api/scan
  - Body: { "domain": "example.com" }

  Returns WHOIS data (Intended for terminal/API use or frontend integration)

✅ 3. Cybersecurity Booking System
  - POST /api/book-meeting
    - Book a cybersecurity expert consultation

  - GET /api/bookings
    - View all pending/approved meetings

  - PUT /api/bookings/<booking_id>/status
    - Update booking status (e.g., "Approved")

✅ 4. Security Alert Dashboard
  - GET /api/alerts
    - Pulls recent CVE vulnerabilities from the NIST API


