#!/bin/bash

# Helm Chart Rollback Demonstration Script
# This script demonstrates rolling back Helm releases to previous versions

set -e

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
NAMESPACE_DEV="azni-dev"
NAMESPACE_PROD="azni-prod"
RELEASE_NAME_DEV="azni-app-dev"
RELEASE_NAME_PROD="azni-app-prod"

print_status "Starting Helm Chart Rollback Demonstration"
echo "============================================="

# Function to show release history
show_release_history() {
    local release_name=$1
    local namespace=$2
    
    print_status "Release history for $release_name in $namespace:"
    helm history $release_name -n $namespace
    echo ""
}

# Function to show current release status
show_release_status() {
    local release_name=$1
    local namespace=$2
    
    print_status "Current status of $release_name in $namespace:"
    helm status $release_name -n $namespace --show-desc
    echo ""
    print_status "Current pods:"
    kubectl get pods -n $namespace -l app.kubernetes.io/instance=$release_name -o wide
    echo ""
}

# Function to perform rollback
perform_rollback() {
    local release_name=$1
    local namespace=$2
    local revision=$3
    local description=$4
    
    print_status "Rolling back $release_name to revision $revision..."
    print_status "Reason: $description"
    
    # Show current revision before rollback
    current_revision=$(helm history $release_name -n $namespace --max 1 -o json | jq -r '.[0].revision')
    print_status "Current revision: $current_revision"
    
    # Perform rollback
    helm rollback $release_name $revision -n $namespace \
        --wait --timeout=300s
    
    # Show new revision after rollback
    new_revision=$(helm history $release_name -n $namespace --max 1 -o json | jq -r '.[0].revision')
    print_success "Rollback completed! New revision: $new_revision"
    
    # Verify rollback
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$release_name -n $namespace --timeout=300s
    print_success "Pods are ready after rollback"
    echo ""
}

# Function to simulate a problematic deployment
simulate_problematic_deployment() {
    local release_name=$1
    local namespace=$2
    local chart_path=$3
    
    print_warning "Simulating a problematic deployment for $release_name..."
    
    # Create a problematic values file
    cat > values-problematic.yaml << EOF
# Problematic configuration for rollback demonstration
global:
  environment: testing

replicaCount: 10  # Too many replicas

image:
  repository: nginx
  pullPolicy: Always
  tag: "nonexistent-tag"  # This will cause image pull errors

mysql:
  rootPassword: "problematic-password"
  database: "problematic_db"
  user: "problematic_user"
  password: "problematic-password"
  
  persistence:
    enabled: true
    storageClass: "nonexistent-storage-class"  # This will cause PVC creation to fail
    size: 1000Gi  # Unreasonably large size

resources:
  limits:
    cpu: 10000m    # Unreasonably high CPU request
    memory: 100Gi  # Unreasonably high memory request
  requests:
    cpu: 5000m
    memory: 50Gi

# This will likely fail due to resource constraints
EOF

    # Attempt the problematic upgrade
    print_status "Attempting problematic upgrade (this is expected to have issues)..."
    if helm upgrade $release_name $chart_path -n $namespace -f values-problematic.yaml \
        --description "Problematic deployment for rollback demo" \
        --wait --timeout=60s; then
        print_warning "Problematic deployment succeeded unexpectedly"
    else
        print_warning "Problematic deployment failed as expected"
    fi
    
    # Clean up the problematic values file
    rm -f values-problematic.yaml
    
    # Show the current state
    print_status "Current state after problematic deployment:"
    kubectl get pods -n $namespace -l app.kubernetes.io/instance=$release_name
    echo ""
}

# Check if releases exist
print_status "Checking if releases exist..."

if ! helm status $RELEASE_NAME_DEV -n $NAMESPACE_DEV &> /dev/null; then
    print_error "Development release $RELEASE_NAME_DEV not found in namespace $NAMESPACE_DEV"
    print_status "Please run ./deploy-complete-workflow.sh first"
    exit 1
fi

if ! helm status $RELEASE_NAME_PROD -n $NAMESPACE_PROD &> /dev/null; then
    print_error "Production release $RELEASE_NAME_PROD not found in namespace $NAMESPACE_PROD"
    print_status "Please run ./deploy-complete-workflow.sh first"
    exit 1
fi

print_success "Both releases found"

# Show initial status and history
print_status "=== INITIAL STATUS AND HISTORY ==="
show_release_history $RELEASE_NAME_DEV $NAMESPACE_DEV
show_release_status $RELEASE_NAME_DEV $NAMESPACE_DEV

show_release_history $RELEASE_NAME_PROD $NAMESPACE_PROD
show_release_status $RELEASE_NAME_PROD $NAMESPACE_PROD

# Simulate problematic deployment for development
print_status "=== SIMULATING PROBLEMATIC DEPLOYMENT (DEVELOPMENT) ==="
simulate_problematic_deployment $RELEASE_NAME_DEV $NAMESPACE_DEV "."

# Show history after problematic deployment
print_status "=== HISTORY AFTER PROBLEMATIC DEPLOYMENT ==="
show_release_history $RELEASE_NAME_DEV $NAMESPACE_DEV

# Get the revision to rollback to (previous working revision)
print_status "Determining revision to rollback to..."
# Get the second-to-last revision (the last working one before the problematic deployment)
rollback_revision=$(helm history $RELEASE_NAME_DEV -n $NAMESPACE_DEV -o json | jq -r '.[-2].revision')
print_status "Will rollback to revision: $rollback_revision"

# Perform rollback for development
print_status "=== PERFORMING ROLLBACK (DEVELOPMENT) ==="
perform_rollback $RELEASE_NAME_DEV $NAMESPACE_DEV $rollback_revision "Rollback due to problematic deployment with resource issues"

# Show status after rollback
print_status "=== STATUS AFTER ROLLBACK (DEVELOPMENT) ==="
show_release_status $RELEASE_NAME_DEV $NAMESPACE_DEV
show_release_history $RELEASE_NAME_DEV $NAMESPACE_DEV

# Demonstrate rollback to specific revision for production
print_status "=== DEMONSTRATING SPECIFIC REVISION ROLLBACK (PRODUCTION) ==="

# Get the first revision for production rollback demo
first_revision=$(helm history $RELEASE_NAME_PROD -n $NAMESPACE_PROD -o json | jq -r '.[0].revision')
print_status "Rolling back production to first revision: $first_revision"

perform_rollback $RELEASE_NAME_PROD $NAMESPACE_PROD $first_revision "Demonstration of rollback to initial deployment"

# Show status after production rollback
print_status "=== STATUS AFTER ROLLBACK (PRODUCTION) ==="
show_release_status $RELEASE_NAME_PROD $NAMESPACE_PROD
show_release_history $RELEASE_NAME_PROD $NAMESPACE_PROD

# Demonstrate rollback to previous revision (shorthand)
print_status "=== DEMONSTRATING ROLLBACK TO PREVIOUS REVISION ==="
print_status "Rolling back production to previous revision using shorthand..."

helm rollback $RELEASE_NAME_PROD -n $NAMESPACE_PROD \
    --wait --timeout=300s

print_success "Rollback to previous revision completed"

# Final status
print_status "=== FINAL STATUS ==="
show_release_history $RELEASE_NAME_DEV $NAMESPACE_DEV
show_release_history $RELEASE_NAME_PROD $NAMESPACE_PROD

print_success "Helm Chart Rollback Demonstration completed successfully!"
echo ""
echo "Summary of rollback operations:"
echo "- Development: Rolled back from problematic deployment"
echo "- Production: Demonstrated rollback to specific revision and previous revision"
echo ""
echo "Key rollback commands demonstrated:"
echo "- helm rollback <release> <revision> -n <namespace>"
echo "- helm rollback <release> -n <namespace>  # Rollback to previous revision"
echo ""
echo "Next steps:"
echo "- Monitor applications: kubectl get pods --all-namespaces"
echo "- Check release status: helm status <release> -n <namespace>"
echo "- View history: helm history <release> -n <namespace>"
