pipeline {
  agent any

  environment {
    AWS_REGION       = 'eu-north-1'
    ECR_REPO         = '423623847692.dkr.ecr.eu-north-1.amazonaws.com/dugma-webapp'
    IMAGE_TAG        = 'latest'
    CLUSTER_NAME     = 'eks_mause'
    APP_NAME         = 'flask-app'
    HELM_CHART_PATH  = 'WebApp/helm-chart/'
    GIT_REPO         = 'https://github.com/DugiBeat/final-devops-app.git'
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: "${GIT_REPO}"
      }
    }

    stage('Docker Build & Push to ECR') {
      steps {
        script {
          sh '''
            echo "🔐 Logging in to AWS ECR..."
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

            echo "🐳 Building Docker image..."
            docker build -t $ECR_REPO:$IMAGE_TAG ./WebApp

            echo "📤 Pushing image to ECR..."
            docker push $ECR_REPO:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Update Kubeconfig') {
      steps {
        sh '''
          echo "⚙️ Updating kubeconfig for EKS cluster..."
          aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
        '''
      }
    }

    stage('Helm Deploy App') {
      steps {
        sh '''
          echo "🚀 Deploying Flask app with Helm..."
          helm upgrade --install $APP_NAME $HELM_CHART_PATH \
            --namespace flask --create-namespace \
            --set image.repository=$ECR_REPO \
            --set image.tag=$IMAGE_TAG
        '''
      }
    }

    stage('Helm Deploy Monitoring (Prometheus + Grafana)') {
      steps {
        sh '''
           echo "📡 Setting up Helm repos..."
           helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
           helm repo add grafana https://grafana.github.io/helm-charts
           helm repo update

           echo "📈 Installing Prometheus..."
           helm upgrade --install prometheus prometheus-community/prometheus \
              --namespace monitoring --create-namespace \
              --set server.service.type=LoadBalancer

           echo "📊 Installing Grafana..."
           helm upgrade --install grafana grafana/grafana \
              --namespace monitoring --create-namespace \
              -f $HELM_CHART_PATH/grafana-values.yaml

           echo "🌐 Patching Prometheus service to LoadBalancer..."
            kubectl patch svc prometheus-server --namespace monitoring --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'
        '''
        
    }
}
    
    stage('Deployment Summary') {
      steps {
        sh '''
            echo "✅ Deployment Summary:"

            # Fetch and display the Flask App LoadBalancer URL
            echo "Flask App URL:"
            kubectl get svc -n flask dugma-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'

            # Fetch and display the Grafana LoadBalancer URL
            echo "Grafana URL:"
            kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'

            # Fetch and display the Prometheus LoadBalancer URL
            echo "Prometheus URL:"
            kubectl get svc -n monitoring prometheus-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
        '''
      }
    }

  post {
    success {
      echo "✅ All components deployed successfully!"
    }
    failure {
      echo "❌ Deployment failed. Please check the logs."
    }
  }

}





