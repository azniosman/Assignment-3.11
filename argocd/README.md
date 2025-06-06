# ArgoCD Setup

This directory contains the configuration files for setting up ArgoCD in your Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (v1.19 or later)
- kubectl configured to communicate with your cluster
- Helm v3 installed

## Installation Steps

1. Install ArgoCD:

```bash
kubectl apply -f install.yaml
```

2. Wait for all ArgoCD pods to be running:

```bash
kubectl get pods -n argocd -w
```

3. Get the ArgoCD admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

4. Port-forward the ArgoCD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

5. Access the ArgoCD UI at https://localhost:8080

   - Username: admin
   - Password: (from step 3)

6. Apply the application configuration:

```bash
kubectl apply -f application.yaml
```

## Configuration Details

- The ArgoCD installation uses the official Helm chart
- Default admin password is set to "admin" (change this in production)
- Insecure mode is enabled for development (disable in production)
- Automated sync and self-healing are enabled
- ApplicationSet and Notifications features are enabled

## Security Considerations

For production environments:

1. Change the default admin password
2. Disable insecure mode
3. Configure proper RBAC
4. Enable SSL/TLS
5. Configure proper authentication

## Troubleshooting

If you encounter issues:

1. Check pod status: `kubectl get pods -n argocd`
2. View pod logs: `kubectl logs -n argocd <pod-name>`
3. Check application sync status in the UI
4. Verify repository access and credentials
