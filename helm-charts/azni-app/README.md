# azni-app Helm Chart

This Helm chart deploys a Nginx application to Kubernetes with customizable configuration.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Namespace `azni-namspace` created in the cluster

## Installing the Chart

To install the chart with the release name `my-release` in the `azni-namspace` namespace:

```bash
helm install my-release ./azni-app -n azni-namspace
```

To install with custom values:

```bash
helm install my-release ./azni-app -n azni-namspace -f values-azni-namspace.yaml
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm uninstall my-release -n azni-namspace
```

## Parameters

### Global parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `replicaCount`            | Number of replicas                              | `2`   |
| `image.repository`        | Image repository                                | `nginx` |
| `image.tag`               | Image tag                                       | `latest` |
| `image.pullPolicy`        | Image pull policy                               | `IfNotPresent` |

### Service parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `service.type`            | Service type                                    | `LoadBalancer` |
| `service.port`            | Service port                                    | `80` |

### Ingress parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `ingress.enabled`         | Enable ingress                                  | `true` |
| `ingress.className`       | Ingress class name                              | `nginx` |
| `ingress.hosts[0].host`   | Hostname                                        | `azni-app.example.com` |

### Resource parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `resources.limits.cpu`    | CPU limits                                      | `200m` |
| `resources.limits.memory` | Memory limits                                   | `256Mi` |
| `resources.requests.cpu`  | CPU requests                                    | `100m` |
| `resources.requests.memory` | Memory requests                               | `128Mi` |

### Autoscaling parameters

| Name                                  | Description                           | Value |
| ------------------------------------- | ------------------------------------- | ----- |
| `autoscaling.enabled`                 | Enable autoscaling                    | `true` |
| `autoscaling.minReplicas`             | Minimum number of replicas            | `2` |
| `autoscaling.maxReplicas`             | Maximum number of replicas            | `5` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization         | `70` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization   | `70` |

## Custom Values for azni-namspace

A custom values file `values-azni-namspace.yaml` has been created with specific configurations for the `azni-namspace` namespace. This includes:

- 3 replicas
- Always pull policy
- Stable image tag
- Higher resource limits
- Namespace-specific ingress host
- Production environment labels

To use these custom values:

```bash
helm install my-release ./azni-app -n azni-namspace -f values-azni-namspace.yaml
```

## Upgrading the Chart

To upgrade the chart with the release name `my-release`:

```bash
helm upgrade my-release ./azni-app -n azni-namspace
```

## Rolling Back a Release

To roll back to a previous release:

```bash
# List releases
helm history my-release -n azni-namspace

# Roll back to a specific revision
helm rollback my-release 1 -n azni-namspace
```
