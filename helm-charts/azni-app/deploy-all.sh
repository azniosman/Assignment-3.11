#!/bin/bash

# Script to deploy both MySQL and frontend components of azni-app to EKS cluster
set -e

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set variables
MYSQL_RELEASE_NAME="azni-app"
FRONTEND_RELEASE_NAME="azni-frontend"
NAMESPACE="azni-mysql"
CHART_PATH="."
MYSQL_VALUES_FILE="values-azni-mysql.yaml"
FRONTEND_VALUES_FILE="values-frontend.yaml"
CLUSTER_NAME="az-eks-cluster"
REGION="us-east-1"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo -e "${YELLOW}Checking for required tools...${NC}"
for cmd in kubectl helm aws jq; do
    if ! command_exists $cmd; then
        echo -e "${RED}Error: $cmd is not installed. Please install it before running this script.${NC}"
        exit 1
    fi
done

# Update kubeconfig for EKS cluster
echo -e "${YELLOW}Updating kubeconfig for EKS cluster...${NC}"
if ! aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION; then
    echo -e "${RED}Failed to update kubeconfig. Please check your AWS credentials and cluster name.${NC}"
    exit 1
fi

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating namespace $NAMESPACE if it doesn't exist...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Check if secrets exist and create them if needed
echo -e "${YELLOW}Checking and creating required secrets...${NC}"
if ! kubectl get secret mysql-tls -n $NAMESPACE &>/dev/null; then
    echo -e "${YELLOW}WARNING: TLS secret mysql-tls not found. You may need to create it manually.${NC}"
fi

if ! kubectl get secret frontend-tls -n $NAMESPACE &>/dev/null; then
    echo -e "${YELLOW}WARNING: TLS secret frontend-tls not found. You may need to create it manually.${NC}"
fi

# Deploy MySQL component
echo -e "${GREEN}Deploying MySQL component...${NC}"
if helm status $MYSQL_RELEASE_NAME -n $NAMESPACE &> /dev/null; then
  echo -e "${YELLOW}Release $MYSQL_RELEASE_NAME already exists. Upgrading...${NC}"
  helm upgrade $MYSQL_RELEASE_NAME $CHART_PATH -n $NAMESPACE -f $MYSQL_VALUES_FILE
else
  echo -e "${GREEN}Installing new release $MYSQL_RELEASE_NAME...${NC}"
  helm install $MYSQL_RELEASE_NAME $CHART_PATH -n $NAMESPACE -f $MYSQL_VALUES_FILE
fi

# Wait for MySQL to be ready
echo -e "${YELLOW}Waiting for MySQL deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/$MYSQL_RELEASE_NAME -n $NAMESPACE || {
    echo -e "${RED}MySQL deployment failed to become ready within the timeout period.${NC}"
    echo -e "${YELLOW}Continuing with frontend deployment anyway...${NC}"
}

# Deploy Frontend component
echo -e "${GREEN}Deploying Frontend component...${NC}"
if helm status $FRONTEND_RELEASE_NAME -n $NAMESPACE &> /dev/null; then
  echo -e "${YELLOW}Release $FRONTEND_RELEASE_NAME already exists. Upgrading...${NC}"
  helm upgrade $FRONTEND_RELEASE_NAME $CHART_PATH -n $NAMESPACE -f $FRONTEND_VALUES_FILE
else
  echo -e "${GREEN}Installing new release $FRONTEND_RELEASE_NAME...${NC}"
  helm install $FRONTEND_RELEASE_NAME $CHART_PATH -n $NAMESPACE -f $FRONTEND_VALUES_FILE
fi

# Check deployment status
echo -e "${GREEN}Checking deployment status...${NC}"
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

# Display access information
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${GREEN}You can access the MySQL service at: $(kubectl get svc -n $NAMESPACE -l "app.kubernetes.io/instance=$MYSQL_RELEASE_NAME" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'):3306${NC}"
echo -e "${GREEN}Or via NodePort at: $(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):30307${NC}"
echo -e "${GREEN}You can access the Frontend at: $(kubectl get svc -n $NAMESPACE -l "app.kubernetes.io/instance=$FRONTEND_RELEASE_NAME" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')${NC}"
echo -e "${GREEN}Or via NodePort at: $(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):30080${NC}"
