#!/bin/bash

# Simple Helm Chart Upgrade Demonstration Script
# This script demonstrates upgrading Helm releases with simple configuration changes

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
NAMESPACE_DEV="azni-dev"
NAMESPACE_PROD="azni-prod"
RELEASE_NAME_DEV="azni-app-dev"
RELEASE_NAME_PROD="azni-app-prod"

print_status "Starting Simple Helm Chart Upgrade Demonstration"
echo "=================================================="

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

# Show initial status
print_status "=== INITIAL STATUS ==="
show_release_status $RELEASE_NAME_DEV $NAMESPACE_DEV
show_release_status $RELEASE_NAME_PROD $NAMESPACE_PROD

# Create upgrade values for development (simple changes)
print_status "Creating upgrade values for development..."
cat > values-dev-upgrade.yaml << EOF
# Development upgrade values
global:
  environment: development

replicaCount: 2  # Increased from 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"  # Upgraded from latest

# Disable MySQL to avoid PVC issues
mysql: {}

frontend:
  enabled: true
  replicaCount: 2  # Increased from 1
  
  image:
    repository: nginx
    tag: "1.21"
    pullPolicy: IfNotPresent
  
  service:
    type: LoadBalancer
    port: 80
    targetPort: 80

service:
  type: LoadBalancer
  port: 80

ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: azni-app-dev.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 150m    # Increased from 100m
    memory: 192Mi # Increased from 128Mi
  requests:
    cpu: 75m     # Increased from 50m
    memory: 96Mi  # Increased from 64Mi

autoscaling:
  enabled: true  # Enabled
  minReplicas: 2
  maxReplicas: 4
  targetCPUUtilizationPercentage: 75

networkPolicy:
  enabled: false

validationHooks:
  enabled: false

nodeSelector:
  kubernetes.io/os: linux

tolerations: []
affinity: {}
EOF

print_success "Development upgrade values created"

# Upgrade development environment
print_status "=== UPGRADING DEVELOPMENT ENVIRONMENT ==="
print_status "Upgrading $RELEASE_NAME_DEV with increased replicas and resources..."

current_revision=$(helm history $RELEASE_NAME_DEV -n $NAMESPACE_DEV --max 1 -o json | jq -r '.[0].revision')
print_status "Current revision: $current_revision"

helm upgrade $RELEASE_NAME_DEV . -n $NAMESPACE_DEV -f values-dev-upgrade.yaml \
    --description "Simple upgrade demo: increased replicas and resources" \
    --wait --timeout=300s

new_revision=$(helm history $RELEASE_NAME_DEV -n $NAMESPACE_DEV --max 1 -o json | jq -r '.[0].revision')
print_success "Upgrade completed! New revision: $new_revision"

# Verify upgrade
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME_DEV -n $NAMESPACE_DEV --timeout=300s
print_success "Pods are ready after upgrade"

# Show post-upgrade status
print_status "=== POST-UPGRADE STATUS (DEVELOPMENT) ==="
show_release_status $RELEASE_NAME_DEV $NAMESPACE_DEV

# Show upgrade history
print_status "=== UPGRADE HISTORY (DEVELOPMENT) ==="
helm history $RELEASE_NAME_DEV -n $NAMESPACE_DEV
echo ""

# Create upgrade values for production
print_status "Creating upgrade values for production..."
cat > values-prod-upgrade.yaml << EOF
# Production upgrade values
global:
  environment: production

replicaCount: 3  # Increased from 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

# Disable MySQL to avoid complexity
mysql: {}

frontend:
  enabled: true
  replicaCount: 3  # Increased from 2
  
  image:
    repository: nginx
    tag: "1.21"
    pullPolicy: IfNotPresent
  
  service:
    type: LoadBalancer
    port: 80
    targetPort: 80
  
  resources:
    limits:
      cpu: 250m     # Increased from 200m
      memory: 320Mi # Increased from 256Mi
    requests:
      cpu: 125m     # Increased from 100m
      memory: 160Mi # Increased from 128Mi

service:
  type: LoadBalancer
  port: 80

ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: azni-app-prod.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 250m
    memory: 320Mi
  requests:
    cpu: 125m
    memory: 160Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 6  # Increased from 4
  targetCPUUtilizationPercentage: 65  # Decreased for more aggressive scaling

networkPolicy:
  enabled: false

validationHooks:
  enabled: false

nodeSelector:
  kubernetes.io/os: linux

tolerations: []
affinity: {}
EOF

print_success "Production upgrade values created"

# Upgrade production environment
print_status "=== UPGRADING PRODUCTION ENVIRONMENT ==="
print_status "Upgrading $RELEASE_NAME_PROD with enhanced performance and scaling..."

current_revision=$(helm history $RELEASE_NAME_PROD -n $NAMESPACE_PROD --max 1 -o json | jq -r '.[0].revision')
print_status "Current revision: $current_revision"

helm upgrade $RELEASE_NAME_PROD . -n $NAMESPACE_PROD -f values-prod-upgrade.yaml \
    --description "Production upgrade: enhanced performance and scaling" \
    --wait --timeout=300s

new_revision=$(helm history $RELEASE_NAME_PROD -n $NAMESPACE_PROD --max 1 -o json | jq -r '.[0].revision')
print_success "Upgrade completed! New revision: $new_revision"

# Verify upgrade
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME_PROD -n $NAMESPACE_PROD --timeout=300s
print_success "Pods are ready after upgrade"

# Show post-upgrade status
print_status "=== POST-UPGRADE STATUS (PRODUCTION) ==="
show_release_status $RELEASE_NAME_PROD $NAMESPACE_PROD

# Show upgrade history
print_status "=== UPGRADE HISTORY (PRODUCTION) ==="
helm history $RELEASE_NAME_PROD -n $NAMESPACE_PROD
echo ""

# Clean up temporary files
print_status "Cleaning up temporary files..."
rm -f values-dev-upgrade.yaml values-prod-upgrade.yaml
print_success "Temporary files cleaned up"

print_success "Simple Helm Chart Upgrade Demonstration completed successfully!"
echo ""
echo "Summary of upgrades:"
echo "- Development: Increased replicas to 2, upgraded image tag, enabled autoscaling"
echo "- Production: Increased replicas to 3, enhanced resources, improved scaling limits"
echo ""
echo "Next steps:"
echo "- Test rollback: ./rollback-demo.sh"
echo "- Monitor performance: kubectl top pods --all-namespaces"
echo "- Check autoscaling: kubectl get hpa --all-namespaces"
