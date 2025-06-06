#!/bin/bash

# Script to deploy frontend for azni-app Helm chart to EKS cluster

# Set variables
RELEASE_NAME="azni-frontend"
NAMESPACE="azni-mysql"
CHART_PATH="."
VALUES_FILE="values-frontend.yaml"

# Update kubeconfig for EKS cluster
echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name az-eks-cluster --region us-east-1

# Create namespace if it doesn't exist
echo "Creating namespace $NAMESPACE if it doesn't exist..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

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
kubectl get pods -n $NAMESPACE -l "app.kubernetes.io/instance=$RELEASE_NAME"
kubectl get svc -n $NAMESPACE -l "app.kubernetes.io/instance=$RELEASE_NAME"
kubectl get ingress -n $NAMESPACE -l "app.kubernetes.io/instance=$RELEASE_NAME"

echo "Frontend deployment completed!"
echo "You can access the frontend at: http://$(kubectl get svc -n $NAMESPACE -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')"
echo "Or via NodePort at: http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):30080"
