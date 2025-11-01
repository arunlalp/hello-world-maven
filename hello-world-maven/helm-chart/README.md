# Hello World Maven Helm Chart

This Helm chart deploys a Hello World Java application built with Maven, SparkJava web framework, and Prometheus metrics support to a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Container image of the application built using the provided Dockerfile

## Installing the Chart

### Prerequisites for Azure Container Registry (ACR)

If your image is stored in Azure Container Registry, you'll need to:

1. **Create an image pull secret for ACR authentication:**

```bash
# Using Azure CLI (recommended)
az aks update -n myAKSCluster -g myResourceGroup --attach-acr myACRName

# Or create a secret manually
kubectl create secret docker-registry acr-secret \
  --docker-server=your-acr-name.azurecr.io \
  --docker-username=your-acr-username \
  --docker-password=your-acr-password \
  --docker-email=your-email@example.com
```

2. **Build and push your image to ACR:**

```bash
# Build the image
docker build -t your-acr-name.azurecr.io/hello-world-maven:latest .

# Login to ACR
az acr login --name your-acr-name

# Push the image
docker push your-acr-name.azurecr.io/hello-world-maven:latest
```

### Installation

To install the chart with the release name `my-hello-world`:

```bash
# Install the chart with ACR image
helm install my-hello-world ./helm-chart \
  --set image.repository=your-acr-name.azurecr.io/hello-world-maven \
  --set image.tag=latest
```

## Uninstalling the Chart

To uninstall/delete the `my-hello-world` deployment:

```bash
helm delete my-hello-world
```

## Configuration

The following table lists the configurable parameters of the Hello World Maven chart and their default values.

### Application Configuration

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Container image repository | `your-acr-name.azurecr.io/hello-world-maven` |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `image.tag` | Container image tag | `""` (uses appVersion) |
| `imagePullSecrets` | Image pull secrets for private registries | `[{name: "acr-secret"}]` |
| `nameOverride` | Partially override chart name | `""` |
| `fullnameOverride` | Fully override chart name | `""` |

### Service Configuration

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `4567` |

### Ingress Configuration

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | Ingress TLS configuration | `[]` |

### Resource Management

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `256Mi` |

### Autoscaling

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `100` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |

### Monitoring

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `monitoring.enabled` | Enable monitoring | `true` |
| `monitoring.serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus | `true` |
| `monitoring.serviceMonitor.path` | Metrics endpoint path | `/metrics` |
| `monitoring.serviceMonitor.interval` | Scrape interval | `30s` |

### Security

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `serviceAccount.create` | Create ServiceAccount | `true` |
| `serviceAccount.annotations` | ServiceAccount annotations | `{}` |
| `podSecurityContext.fsGroup` | Pod fsGroup | `1000` |
| `securityContext.runAsUser` | Container runAsUser | `1000` |
| `securityContext.runAsNonRoot` | Run as non-root | `true` |

## Application Features

This application provides the following endpoints:

- `GET /` - Welcome page
- `GET /hello` - Hello world message
- `GET /greet/:name` - Personalized greeting
- `GET /metrics` - Prometheus metrics (for monitoring)

## Examples

### Basic Installation

```bash
helm install my-app ./helm-chart
```

### Installation with ACR Image

```bash
# Basic installation with ACR
helm install my-app ./helm-chart \
  --set image.repository=your-acr-name.azurecr.io/hello-world-maven \
  --set image.tag=v1.0.0

# With custom service type
helm install my-app ./helm-chart \
  --set image.repository=your-acr-name.azurecr.io/hello-world-maven \
  --set image.tag=v1.0.0 \
  --set service.type=LoadBalancer \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=hello.example.com
```

### Installation with ACR Values File

For Azure Container Registry deployments, use the provided ACR values file:

```bash
# Update the ACR name in values-acr.yaml first, then:
helm install my-app ./helm-chart -f values-acr.yaml
```

## Azure Container Registry (ACR) Setup

### Method 1: AKS ACR Integration (Recommended)

If you're using Azure Kubernetes Service (AKS), the easiest way is to attach your ACR to your AKS cluster:

```bash
# Attach ACR to AKS cluster
az aks update -n <aks-cluster-name> -g <resource-group> --attach-acr <acr-name>
```

This eliminates the need for manual image pull secrets.

### Method 2: Manual Secret Creation

If you need to create the image pull secret manually:

```bash
# Get ACR credentials
ACR_NAME="your-acr-name"
ACR_USERNAME=$(az acr credential show -n $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show -n $ACR_NAME --query passwords[0].value -o tsv)

# Create Kubernetes secret
kubectl create secret docker-registry acr-secret \
  --docker-server=$ACR_NAME.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --docker-email=any-email@example.com
```

### Method 3: Using Azure AD Service Principal

For production environments, consider using a service principal:

```bash
# Create service principal with ACR pull permissions
az ad sp create-for-rbac --name myAKSClusterServicePrincipal --skip-assignment

# Get ACR resource ID
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query id --output tsv)

# Assign pull permission to service principal
az role assignment create --assignee $SERVICE_PRINCIPAL_ID --scope $ACR_ID --role acrpull
```

```yaml
image:
  repository: my-registry/hello-world-maven
  tag: v1.0.0

service:
  type: LoadBalancer

ingress:
  enabled: true
  hosts:
    - host: hello.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

Then install:

```bash
helm install my-app ./helm-chart -f custom-values.yaml
```

## Monitoring Setup

If you have Prometheus Operator installed, the chart will automatically create a ServiceMonitor resource to scrape metrics from your application's `/metrics` endpoint.

To disable monitoring:

```bash
helm install my-app ./helm-chart --set monitoring.enabled=false
```

## Development and Testing

### Linting the Chart

```bash
helm lint ./helm-chart
```

### Rendering Templates

```bash
helm template my-app ./helm-chart
```

### Dry Run Installation

```bash
helm install my-app ./helm-chart --dry-run --debug
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=hello-world-maven
```

### View Application Logs

```bash
kubectl logs -l app.kubernetes.io/name=hello-world-maven
```

### Access Application Locally

```bash
kubectl port-forward svc/my-hello-world 8080:80
curl http://localhost:8080
```

### Check Metrics

```bash
kubectl port-forward svc/my-hello-world 8080:80
curl http://localhost:8080/metrics
```