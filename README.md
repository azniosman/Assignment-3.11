# Assignment 3.11 - Helm Charts for Kubernetes

This repository contains Helm charts for deploying applications to Kubernetes.

## Repository Structure

```
.
└── helm-charts/
    └── azni-app/
        ├── Chart.yaml
        ├── values.yaml
        ├── values-azni-mysql.yaml
        ├── templates/
        ├── charts/
        ├── README.md
        ├── deploy.sh
        ├── rollback.sh
        └── uninstall.sh
```

## Helm Charts

### azni-app

A Helm chart for deploying a MySQL application to Kubernetes. The chart includes:

- Deployment with configurable replicas
- Service (LoadBalancer)
- Ingress with TLS
- Horizontal Pod Autoscaler
- Resource limits and requests
- Liveness and readiness probes

For more details, see the [azni-app README](helm-charts/azni-app/README.md).

## Deployment

The Helm charts are configured to be deployed to the `azni-mysql` namespace on the `dev-eks-cluster` EKS cluster.

### Prerequisites

- AWS CLI configured with appropriate credentials
- kubectl installed and configured
- Helm 3.x installed

### Deploying a Chart

To deploy the azni-app chart:

```bash
cd helm-charts/azni-app
./deploy.sh
```

### Rolling Back a Release

To roll back a release:

```bash
cd helm-charts/azni-app
./rollback.sh
```

### Uninstalling a Release

To uninstall a release:

```bash
cd helm-charts/azni-app
./uninstall.sh
```

## Customization

Each chart includes a default `values.yaml` file and a namespace-specific values file (e.g., `values-azni-mysql.yaml`). You can customize these files to change the behavior of the deployed applications.

## Helm Commands Reference

```bash
# Add a repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Search for charts
helm search repo mysql

# Install a chart
helm install my-release ./azni-app -n azni-mysql

# Upgrade a release
helm upgrade my-release ./azni-app -n azni-mysql

# Rollback a release
helm rollback my-release 1 -n azni-mysql

# Uninstall a release
helm uninstall my-release -n azni-mysql

# List releases
helm list -n azni-mysql

# Get release history
helm history my-release -n azni-mysql

# Package a chart
helm package ./azni-app
```
