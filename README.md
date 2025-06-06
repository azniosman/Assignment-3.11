# Helm and Kustomize Integration with ArgoCD

This repository demonstrates how to use Helm and Kustomize together with ArgoCD for managing Kubernetes applications across different environments.

## Repository Structure

```
.
├── base/                    # Base Kustomize configuration
│   ├── kustomization.yaml
│   └── helm-release.yaml    # Helm release definition
├── overlays/               # Environment-specific overlays
│   ├── development/
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── values.yaml
└── argocd/                 # ArgoCD application definitions
    ├── applications/
    │   ├── development.yaml
    │   └── production.yaml
    └── projects/
        └── demo-project.yaml
```

## How It Works

1. **Helm Charts**: We use Helm charts to package our application and its dependencies.
2. **Kustomize**: We use Kustomize to customize the Helm releases for different environments.
3. **ArgoCD**: ArgoCD manages the deployment of our customized Helm releases.

## Setup Instructions

1. Install required tools:

   ```bash
   # Install Helm
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

   # Install Kustomize
   curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

   # Install ArgoCD CLI
   brew install argocd
   ```

2. Add the Helm repository:

   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```

3. Deploy ArgoCD:

   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

4. Apply the ArgoCD applications:
   ```bash
   kubectl apply -f argocd/projects/demo-project.yaml
   kubectl apply -f argocd/applications/
   ```

## Environment-Specific Configuration

- **Development**: Uses minimal resources and debug settings
- **Production**: Uses production-grade resources and security settings

## Best Practices

1. Always use semantic versioning for Helm charts
2. Keep sensitive values in sealed secrets
3. Use ArgoCD's sync waves for proper deployment order
4. Implement health checks and readiness probes
5. Use resource quotas and limits
6. Implement proper RBAC policies

## Troubleshooting

1. Check ArgoCD application status:

   ```bash
   argocd app get <app-name>
   ```

2. View application logs:

   ```bash
   argocd app logs <app-name>
   ```

3. Sync application manually:
   ```bash
   argocd app sync <app-name>
   ```

## Security Considerations

1. Use sealed secrets for sensitive data
2. Implement network policies
3. Use service accounts with minimal permissions
4. Enable RBAC
5. Regular security scanning of container images
