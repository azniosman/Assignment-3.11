# Azni-App Helm Chart

A comprehensive Helm chart for deploying a MySQL application with a frontend dashboard to Kubernetes.

## Features

- **MySQL Database**: Configurable MySQL deployment with persistence
- **Frontend Dashboard**: Nginx-based web UI for visualization
- **Scalability**: Horizontal Pod Autoscaler for both components
- **Security**:
  - Kubernetes Secrets for sensitive data
  - Network Policies for restricted access
  - TLS configuration for secure ingress
- **High Availability**: Pod anti-affinity rules for better distribution
- **Monitoring**: Prometheus readiness for observability
- **Validation**: Pre/post deployment hooks for validation

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- AWS EKS Cluster (for default configuration)
- kubectl configured to communicate with your cluster
- AWS CLI configured with appropriate permissions

## Installation

### Add the Repository (if hosted externally)

```bash
helm repo add azni-repo https://your-repo-url.com
helm repo update
```

### Install the MySQL Component

```bash
cd helm-charts/azni-app
./deploy.sh
```

This script will:

1. Update kubeconfig for the EKS cluster
2. Create the namespace if it doesn't exist
3. Install/upgrade the MySQL release

### Install the Frontend Component

```bash
cd helm-charts/azni-app
./deploy-frontend.sh
```

### Install Both Components at Once

```bash
cd helm-charts/azni-app
./deploy-all.sh
```

## Configuration

### Global Parameters

| Parameter            | Description                                    | Default       |
| -------------------- | ---------------------------------------------- | ------------- |
| `global.environment` | Environment (development, staging, production) | `development` |

### MySQL Parameters

| Parameter                  | Description                            | Default                |
| -------------------------- | -------------------------------------- | ---------------------- |
| `replicaCount`             | Number of MySQL replicas               | `1`                    |
| `image.repository`         | MySQL image repository                 | `mysql`                |
| `image.tag`                | MySQL image tag                        | `5.7`                  |
| `mysql.rootPassword`       | MySQL root password (stored in Secret) | `""` (random if empty) |
| `mysql.database`           | MySQL database name                    | `azni_db`              |
| `mysql.user`               | MySQL username                         | `azni_user`            |
| `mysql.password`           | MySQL password (stored in Secret)      | `""` (random if empty) |
| `persistence.enabled`      | Enable persistence for MySQL data      | `true`                 |
| `persistence.size`         | PVC size                               | `10Gi`                 |
| `persistence.storageClass` | Storage class for PVC                  | `gp2`                  |
| `service.type`             | Service type                           | `NodePort`             |
| `service.port`             | Service port                           | `3306`                 |
| `service.nodePort`         | NodePort (if applicable)               | `30307`                |
| `networkPolicy.enabled`    | Enable NetworkPolicy                   | `true` (in production) |

### Frontend Parameters

| Parameter             | Description                 | Default                    |
| --------------------- | --------------------------- | -------------------------- |
| `replicaCount`        | Number of frontend replicas | `2`                        |
| `image.repository`    | Frontend image repository   | `nginx`                    |
| `image.tag`           | Frontend image tag          | `stable`                   |
| `service.type`        | Service type                | `NodePort`                 |
| `service.port`        | Service port                | `80`                       |
| `service.nodePort`    | NodePort (if applicable)    | `30080`                    |
| `ingress.enabled`     | Enable ingress              | `true`                     |
| `ingress.annotations` | Ingress annotations         | See values.yaml            |
| `ingress.hosts`       | Ingress hosts               | `frontend.your-domain.com` |

## Security Considerations

### Credential Management

Production deployments should use external secrets management:

```yaml
mysql:
  # Instead of putting actual passwords in values files
  existingSecret: "my-external-secret"
```

### Network Security

Network policies are enabled by default in production environments:

```yaml
networkPolicy:
  enabled: true
  additionalIngressRules:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
```

## Maintenance

### Upgrading

```bash
helm upgrade my-release ./azni-app -n azni-mysql -f values-custom.yaml
```

### Rolling Back

```bash
./rollback.sh
```

### Uninstalling

```bash
./uninstall.sh
```

## Development and Customization

### Creating Environment-Specific Values

1. Copy an existing values file:

   ```bash
   cp values-azni-mysql.yaml values-staging.yaml
   ```

2. Modify parameters as needed:

   ```yaml
   global:
     environment: staging
   replicaCount: 2
   ```

3. Deploy using the custom values:
   ```bash
   helm install my-release ./azni-app -n azni-staging -f values-staging.yaml
   ```

### Adding Custom Templates

The chart structure follows standard Helm conventions. To add a custom template:

1. Create your template in the `templates/` directory
2. Define relevant values in `values.yaml`
3. Use the helper functions for consistent naming:
   ```yaml
   { { - include "azni-app.fullname" . } }
   ```

## Troubleshooting

### Common Issues

- **PVC Creation Failure**: Check storage class availability

  ```bash
  kubectl get sc
  ```

- **Secret Access Issues**: Verify secret exists and has correct format

  ```bash
  kubectl get secret -n azni-mysql
  kubectl describe secret azni-app-mysql-secrets -n azni-mysql
  ```

- **Network Policy Blocking**: If pods can't communicate, check network policies
  ```bash
  kubectl get networkpolicies -n azni-mysql
  ```

## License

This Helm chart is licensed under the MIT License.
