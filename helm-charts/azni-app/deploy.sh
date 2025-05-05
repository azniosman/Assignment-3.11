#!/bin/bash

# Script to deploy azni-app Helm chart to EKS cluster

# Set variables
RELEASE_NAME="azni-app"
NAMESPACE="azni-namspace"
CHART_PATH="."
VALUES_FILE="values-azni-namspace.yaml"

# Update kubeconfig for EKS cluster
echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name shared-eks-cluster --region us-east-1

# Create namespace if it doesn't exist
echo "Creating namespace $NAMESPACE if it doesn't exist..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories if needed
# helm repo add bitnami https://charts.bitnami.com/bitnami
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo update

# Check if release already exists
if helm status $RELEASE_NAME -n $NAMESPACE &> /dev/null; then
  echo "Release $RELEASE_NAME already exists. Upgrading..."
  helm upgrade $RELEASE_NAME $CHART_PATH -n $NAMESPACE -f $VALUES_FILE
else
  echo "Installing new release $RELEASE_NAME..."
  helm install $RELEASE_NAME $CHART_PATH -n $NAMESPACE -f $VALUES_FILE
fi

# Check deployment status
echo "Checking deployment status..."
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

echo "Deployment completed!"
