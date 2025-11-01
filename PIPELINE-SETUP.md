# Azure DevOps Pipeline Setup for AKS Deployment

This document explains how to set up the Azure DevOps pipeline to build and deploy the Java Maven application to Azure Kubernetes Service (AKS) using Helm.

## Pipeline Overview

The pipeline consists of three main stages:

1. **Build Stage**: Compiles the Java application using Maven
2. **Image Stage**: Builds Docker image and pushes to Azure Container Registry (ACR)
3. **Deploy Stage**: Deploys to AKS using the Helm chart

## Prerequisites

### 1. Azure Resources

- **Azure Container Registry (ACR)**: To store Docker images
- **Azure Kubernetes Service (AKS)**: To run the application
- **Resource Group**: To contain all resources

### 2. Azure DevOps Service Connections

You need to create the following service connections in Azure DevOps:

#### ACR Service Connection
- **Name**: `acr-project-svc-con` (or update the pipeline variable)
- **Type**: Docker Registry
- **Server URL**: `your-acr-name.azurecr.io`
- **Authentication**: Service Principal or Managed Identity

#### AKS Service Connection
- **Name**: `aks-project-svc-con` (or update the pipeline variable)
- **Type**: Kubernetes
- **Server URL**: Your AKS cluster API server URL
- **Authentication**: Service Principal or Azure Service Connection

### 3. Pipeline Variables to Update

Update these variables in `azure-pipelines.yml`:

```yaml
variables:
  # ACR Configuration
  dockerRegistryServiceConnection: 'your-acr-service-connection-name'
  acrLoginServer: 'your-acr-name.azurecr.io'
  
  # AKS Configuration
  aksServiceConnection: 'your-aks-service-connection-name'
  aksClusterName: 'your-aks-cluster-name'
  aksResourceGroup: 'your-resource-group'
  kubernetesNamespace: 'default'  # or your preferred namespace
  helmReleaseName: 'hello-world-maven'  # or your preferred release name
```

## Setup Instructions

### Step 1: Create Azure Resources

```bash
# Set variables
RESOURCE_GROUP="myResourceGroup"
LOCATION="eastus"
ACR_NAME="myacr$(date +%s)"  # ACR names must be globally unique
AKS_NAME="myAKSCluster"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create ACR
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Create AKS cluster
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 2 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Attach ACR to AKS (enables image pulling without secrets)
az aks update -n $AKS_NAME -g $RESOURCE_GROUP --attach-acr $ACR_NAME
```

### Step 2: Create Service Connections in Azure DevOps

1. **Go to Azure DevOps Project Settings > Service Connections**

2. **Create ACR Service Connection:**
   - Click "New service connection"
   - Select "Docker Registry"
   - Choose "Azure Container Registry"
   - Select your subscription and ACR
   - Name it `acr-project-svc-con`

3. **Create AKS Service Connection:**
   - Click "New service connection"
   - Select "Kubernetes"
   - Choose "Azure Subscription"
   - Select your subscription, resource group, and AKS cluster
   - Name it `aks-project-svc-con`

### Step 3: Create Environment (Optional)

1. Go to **Pipelines > Environments**
2. Click "New environment"
3. Name it `production`
4. Add your AKS cluster as a resource (optional, for better tracking)

### Step 4: Update Pipeline Variables

Edit the `azure-pipelines.yml` file with your specific values:

```yaml
variables:
  # Update these with your actual values
  dockerRegistryServiceConnection: 'acr-project-svc-con'
  acrLoginServer: 'myacr123456.azurecr.io'
  aksServiceConnection: 'aks-project-svc-con'
  aksClusterName: 'myAKSCluster'
  aksResourceGroup: 'myResourceGroup'
```

## Pipeline Stages Explained

### Build Stage
- Caches Maven dependencies for faster builds
- Compiles Java application using Maven
- Publishes build artifacts

### Image Stage  
- Logs into ACR using service connection
- Builds Docker image using the Dockerfile
- Tags image with build ID and 'latest'
- Pushes image to ACR

### Deploy Stage
- Installs Helm on the build agent
- Creates ACR pull secret in AKS namespace
- Deploys application using Helm chart
- Sets image repository and tag dynamically
- Verifies deployment by checking pods and services

## Deployment Process

1. **Image Pull Secret**: The pipeline automatically creates an `acr-secret` in the target namespace
2. **Helm Upgrade**: Uses `helm upgrade --install` to deploy or update the application
3. **Dynamic Configuration**: Sets image repository and tag based on build variables
4. **Verification**: Checks pod status and service information after deployment

## Monitoring and Troubleshooting

### View Deployment Status
```bash
# Get pods
kubectl get pods -n default -l app.kubernetes.io/name=hello-world-maven

# Get service
kubectl get svc hello-world-maven-hello-world-maven

# View logs
kubectl logs -l app.kubernetes.io/name=hello-world-maven -n default
```

### Access Application
```bash
# Port forward to access locally
kubectl port-forward svc/hello-world-maven-hello-world-maven 8080:80

# Or if using LoadBalancer service type
kubectl get svc hello-world-maven-hello-world-maven -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Helm Commands
```bash
# Check release status
helm status hello-world-maven

# View release history  
helm history hello-world-maven

# Rollback if needed
helm rollback hello-world-maven 1
```

## Security Considerations

1. **Service Connections**: Use managed identities when possible
2. **Image Pull Secrets**: The pipeline creates these automatically
3. **RBAC**: Ensure proper Kubernetes RBAC is configured
4. **Network Policies**: Consider implementing network policies for pod-to-pod communication
5. **Resource Limits**: The Helm chart includes resource limits by default

## Customization Options

### Different Environments
Create different variable groups or pipeline variables for different environments:

```yaml
# For staging environment
- ${{ if eq(variables['Build.SourceBranchName'], 'develop') }}:
  - name: kubernetesNamespace
    value: 'staging'
  - name: helmReleaseName  
    value: 'hello-world-maven-staging'
```

### Custom Helm Values
You can override Helm values in the deployment step:

```yaml
arguments: >
  --install
  --set image.repository=$(acrLoginServer)/$(imageRepository)
  --set image.tag=$(Build.BuildId)
  --set imagePullSecrets[0].name=acr-secret
  --set service.type=LoadBalancer
  --set ingress.enabled=true
  --set ingress.hosts[0].host=myapp.example.com
  --wait
  --timeout=10m
```

This setup provides a complete CI/CD pipeline that builds your Java application, containerizes it, and deploys it to AKS using Helm with proper security and monitoring configurations.