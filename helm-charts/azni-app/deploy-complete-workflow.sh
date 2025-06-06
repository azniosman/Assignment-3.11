#!/bin/bash

# Complete Helm Chart Workflow Script
# This script demonstrates creating, packaging, and deploying a custom Helm Chart on Amazon EKS

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Set variables
CHART_NAME="azni-app"
CHART_PATH="."
NAMESPACE_DEV="azni-dev"
NAMESPACE_PROD="azni-prod"
RELEASE_NAME_DEV="azni-app-dev"
RELEASE_NAME_PROD="azni-app-prod"

print_status "Starting Complete Helm Chart Workflow for $CHART_NAME"
echo "=================================================="

# Step 1: Validate Helm and Kubernetes connectivity
print_status "Step 1: Validating prerequisites..."

if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed or not in PATH"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check Kubernetes connectivity
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_success "Prerequisites validated successfully"

# Step 2: Update kubeconfig for EKS cluster
print_status "Step 2: Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name az-eks-cluster --region us-east-1
print_success "Kubeconfig updated successfully"

# Step 3: Validate and lint the Helm chart
print_status "Step 3: Validating and linting Helm chart..."
helm lint $CHART_PATH
print_success "Chart validation completed"

# Step 4: Package the Helm chart
print_status "Step 4: Packaging Helm chart..."
helm package $CHART_PATH
PACKAGE_FILE=$(ls ${CHART_NAME}-*.tgz | tail -1)
print_success "Chart packaged as: $PACKAGE_FILE"

# Step 5: Create namespaces
print_status "Step 5: Creating namespaces..."
kubectl create namespace $NAMESPACE_DEV --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $NAMESPACE_PROD --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespaces created/verified"

# Step 6: Deploy to Development environment
print_status "Step 6: Deploying to Development environment..."
if helm status $RELEASE_NAME_DEV -n $NAMESPACE_DEV &> /dev/null; then
    print_warning "Development release exists, upgrading..."
    helm upgrade $RELEASE_NAME_DEV $CHART_PATH -n $NAMESPACE_DEV -f values-development.yaml
else
    print_status "Installing new development release..."
    helm install $RELEASE_NAME_DEV $CHART_PATH -n $NAMESPACE_DEV -f values-development.yaml
fi
print_success "Development deployment completed"

# Step 7: Verify development deployment
print_status "Step 7: Verifying development deployment..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME_DEV -n $NAMESPACE_DEV --timeout=300s
kubectl get pods,svc,ingress -n $NAMESPACE_DEV
print_success "Development deployment verified"

# Step 8: Deploy to Production environment
print_status "Step 8: Deploying to Production environment..."
if helm status $RELEASE_NAME_PROD -n $NAMESPACE_PROD &> /dev/null; then
    print_warning "Production release exists, upgrading..."
    helm upgrade $RELEASE_NAME_PROD $CHART_PATH -n $NAMESPACE_PROD -f values-production.yaml
else
    print_status "Installing new production release..."
    helm install $RELEASE_NAME_PROD $CHART_PATH -n $NAMESPACE_PROD -f values-production.yaml
fi
print_success "Production deployment completed"

# Step 9: Verify production deployment
print_status "Step 9: Verifying production deployment..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME_PROD -n $NAMESPACE_PROD --timeout=300s
kubectl get pods,svc,ingress -n $NAMESPACE_PROD
print_success "Production deployment verified"

# Step 10: Display release information
print_status "Step 10: Displaying release information..."
echo ""
echo "Development Release:"
helm status $RELEASE_NAME_DEV -n $NAMESPACE_DEV
echo ""
echo "Production Release:"
helm status $RELEASE_NAME_PROD -n $NAMESPACE_PROD

# Step 11: Show release history
print_status "Step 11: Showing release history..."
echo ""
echo "Development Release History:"
helm history $RELEASE_NAME_DEV -n $NAMESPACE_DEV
echo ""
echo "Production Release History:"
helm history $RELEASE_NAME_PROD -n $NAMESPACE_PROD

print_success "Complete Helm Chart Workflow finished successfully!"
echo ""
echo "Summary:"
echo "- Chart: $CHART_NAME"
echo "- Package: $PACKAGE_FILE"
echo "- Development: $RELEASE_NAME_DEV in $NAMESPACE_DEV"
echo "- Production: $RELEASE_NAME_PROD in $NAMESPACE_PROD"
echo ""
echo "Next steps:"
echo "- Test upgrade: ./upgrade-demo.sh"
echo "- Test rollback: ./rollback-demo.sh"
echo "- Monitor: kubectl get pods --all-namespaces"
