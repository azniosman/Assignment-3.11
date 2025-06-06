#!/bin/bash

# Helm Chart Upgrade Demonstration Script
# This script demonstrates upgrading Helm releases with different configurations

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
CHART_PATH="."
NAMESPACE_DEV="azni-dev"
NAMESPACE_PROD="azni-prod"
RELEASE_NAME_DEV="azni-app-dev"
RELEASE_NAME_PROD="azni-app-prod"

print_status "Starting Helm Chart Upgrade Demonstration"
echo "============================================="

# Function to show current release status
show_release_status() {
    local release_name=$1
    local namespace=$2
    
    print_status "Current status of $release_name in $namespace:"
    helm status $release_name -n $namespace
    echo ""
    print_status "Current pods:"
    kubectl get pods -n $namespace -l app.kubernetes.io/instance=$release_name
    echo ""
}

# Function to perform upgrade
perform_upgrade() {
    local release_name=$1
    local namespace=$2
    local values_file=$3
    local description=$4
    
    print_status "Upgrading $release_name with $description..."
    
    # Show current revision before upgrade
    current_revision=$(helm history $release_name -n $namespace --max 1 -o json | jq -r '.[0].revision')
    print_status "Current revision: $current_revision"
    
    # Perform upgrade
    helm upgrade $release_name $CHART_PATH -n $namespace -f $values_file \
        --description "$description" \
        --wait --timeout=300s
    
    # Show new revision after upgrade
    new_revision=$(helm history $release_name -n $namespace --max 1 -o json | jq -r '.[0].revision')
    print_success "Upgrade completed! New revision: $new_revision"
    
    # Verify upgrade
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$release_name -n $namespace --timeout=300s
    print_success "Pods are ready after upgrade"
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

# Show initial status
print_status "=== INITIAL STATUS ==="
show_release_status $RELEASE_NAME_DEV $NAMESPACE_DEV
show_release_status $RELEASE_NAME_PROD $NAMESPACE_PROD

# Create a temporary values file for upgrade demonstration
print_status "Creating temporary values file for upgrade demonstration..."
cat > values-upgrade-demo.yaml << EOF
# Upgrade demonstration values
global:
  environment: development

replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"  # Upgraded from latest

mysql:
  rootPassword: "upgraded-dev-password"
  database: "azni_dev_db_v2"
  user: "azni_dev_user"
  password: "upgraded-dev-password"
  
  persistence:
    enabled: true
    storageClass: "gp2"
    size: 8Gi  # Increased from 5Gi

frontend:
  enabled: true
  replicaCount: 2  # Increased from 1
  
  image:
    repository: nginx
    tag: "1.21"  # Upgraded from latest

resources:
  limits:
    cpu: 150m    # Increased from 100m
    memory: 192Mi # Increased from 128Mi
  requests:
    cpu: 75m     # Increased from 50m
    memory: 96Mi  # Increased from 64Mi

autoscaling:
  enabled: true  # Enabled for upgrade demo
  minReplicas: 2
  maxReplicas: 4
  targetCPUUtilizationPercentage: 75
EOF

print_success "Temporary values file created"

# Upgrade development environment
print_status "=== UPGRADING DEVELOPMENT ENVIRONMENT ==="
perform_upgrade $RELEASE_NAME_DEV $NAMESPACE_DEV "values-upgrade-demo.yaml" "Upgrade demo: increased resources and replica count"

# Show upgrade status
print_status "=== POST-UPGRADE STATUS (DEVELOPMENT) ==="
show_release_status $RELEASE_NAME_DEV $NAMESPACE_DEV

# Show upgrade history
print_status "=== UPGRADE HISTORY (DEVELOPMENT) ==="
helm history $RELEASE_NAME_DEV -n $NAMESPACE_DEV
echo ""

# Upgrade production environment with different values
print_status "=== UPGRADING PRODUCTION ENVIRONMENT ==="

# Create production upgrade values
cat > values-prod-upgrade-demo.yaml << EOF
# Production upgrade demonstration values
global:
  environment: production

replicaCount: 4  # Increased from 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

mysql:
  database: "azni_prod_db_v2"
  user: "azni_prod_user"
  
  persistence:
    enabled: true
    storageClass: "gp2"
    size: 75Gi  # Increased from 50Gi
  
  config:
    maxConnections: 750  # Increased from 500
    innodbBufferPoolSize: "1.5G"  # Increased from 1G

frontend:
  enabled: true
  replicaCount: 4  # Increased from 3

resources:
  limits:
    cpu: 750m     # Increased from 500m
    memory: 768Mi # Increased from 512Mi
  requests:
    cpu: 375m     # Increased from 250m
    memory: 384Mi # Increased from 256Mi

autoscaling:
  enabled: true
  minReplicas: 4  # Increased from 3
  maxReplicas: 15 # Increased from 10
  targetCPUUtilizationPercentage: 65  # Decreased from 70 for more aggressive scaling
EOF

perform_upgrade $RELEASE_NAME_PROD $NAMESPACE_PROD "values-prod-upgrade-demo.yaml" "Production upgrade: enhanced performance and scaling"

# Show upgrade status
print_status "=== POST-UPGRADE STATUS (PRODUCTION) ==="
show_release_status $RELEASE_NAME_PROD $NAMESPACE_PROD

# Show upgrade history
print_status "=== UPGRADE HISTORY (PRODUCTION) ==="
helm history $RELEASE_NAME_PROD -n $NAMESPACE_PROD
echo ""

# Clean up temporary files
print_status "Cleaning up temporary files..."
rm -f values-upgrade-demo.yaml values-prod-upgrade-demo.yaml
print_success "Temporary files cleaned up"

print_success "Helm Chart Upgrade Demonstration completed successfully!"
echo ""
echo "Summary of upgrades:"
echo "- Development: Increased resources, enabled autoscaling, upgraded images"
echo "- Production: Enhanced performance, increased scaling limits, optimized configuration"
echo ""
echo "Next steps:"
echo "- Test rollback: ./rollback-demo.sh"
echo "- Monitor performance: kubectl top pods --all-namespaces"
echo "- Check autoscaling: kubectl get hpa --all-namespaces"
