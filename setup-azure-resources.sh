#!/bin/bash

# Azure Resource Setup Script for AKS Deployment
# This script creates the necessary Azure resources for the CI/CD pipeline

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Default values
RESOURCE_GROUP=""
LOCATION="eastus"
ACR_NAME=""
AKS_NAME=""
NODE_COUNT=2

# Function to show usage
usage() {
    echo "Usage: $0 -g <resource-group> -l <location> -a <acr-name> -k <aks-name> [-n <node-count>]"
    echo ""
    echo "Options:"
    echo "  -g, --resource-group    Resource group name (required)"
    echo "  -l, --location         Azure location (default: eastus)"
    echo "  -a, --acr-name         ACR name - must be globally unique (required)"
    echo "  -k, --aks-name         AKS cluster name (required)"
    echo "  -n, --node-count       Number of AKS nodes (default: 2)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -g myResourceGroup -a myacr12345 -k myAKSCluster"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -a|--acr-name)
            ACR_NAME="$2"
            shift 2
            ;;
        -k|--aks-name)
            AKS_NAME="$2"
            shift 2
            ;;
        -n|--node-count)
            NODE_COUNT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$RESOURCE_GROUP" || -z "$ACR_NAME" || -z "$AKS_NAME" ]]; then
    print_error "Missing required parameters"
    usage
fi

# Check if Azure CLI is installed and user is logged in
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

if ! az account show &> /dev/null; then
    print_error "You are not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

print_header "Azure Resources Setup for Hello World Maven Application"

# Display configuration
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"  
echo "  ACR Name: $ACR_NAME"
echo "  AKS Name: $AKS_NAME"
echo "  Node Count: $NODE_COUNT"
echo ""

read -p "Do you want to proceed with this configuration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Operation cancelled by user"
    exit 0
fi

# Create resource group
print_header "Creating Resource Group"
print_status "Creating resource group: $RESOURCE_GROUP in $LOCATION"

if az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none; then
    print_status "Resource group created successfully"
else
    print_error "Failed to create resource group"
    exit 1
fi

# Create ACR
print_header "Creating Azure Container Registry"
print_status "Creating ACR: $ACR_NAME"

if az acr create --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME" --sku Basic --output none; then
    print_status "ACR created successfully"
    ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer --output tsv)
    print_status "ACR Login Server: $ACR_LOGIN_SERVER"
else
    print_error "Failed to create ACR. The name might already be taken globally."
    exit 1
fi

# Create AKS cluster
print_header "Creating Azure Kubernetes Service"
print_status "Creating AKS cluster: $AKS_NAME (this may take 10-15 minutes)"

if az aks create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --node-count "$NODE_COUNT" \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --output none; then
    print_status "AKS cluster created successfully"
else
    print_error "Failed to create AKS cluster"
    exit 1
fi

# Attach ACR to AKS
print_header "Configuring ACR Integration"
print_status "Attaching ACR to AKS cluster for seamless image pulling"

if az aks update -n "$AKS_NAME" -g "$RESOURCE_GROUP" --attach-acr "$ACR_NAME" --output none; then
    print_status "ACR attached to AKS successfully"
else
    print_error "Failed to attach ACR to AKS"
    exit 1
fi

# Get AKS credentials
print_header "Configuring kubectl"
print_status "Getting AKS credentials for kubectl"

if az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --overwrite-existing; then
    print_status "kubectl configured successfully"
else
    print_warning "Failed to configure kubectl. You may need to run this manually:"
    echo "az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME"
fi

# Display summary
print_header "Setup Complete!"

echo -e "${GREEN}✅ Resource Group:${NC} $RESOURCE_GROUP"
echo -e "${GREEN}✅ ACR Name:${NC} $ACR_NAME"
echo -e "${GREEN}✅ ACR Login Server:${NC} $ACR_LOGIN_SERVER"
echo -e "${GREEN}✅ AKS Cluster:${NC} $AKS_NAME"
echo ""

print_header "Next Steps"
echo "1. Update your azure-pipelines.yml with these values:"
echo "   - acrLoginServer: '$ACR_LOGIN_SERVER'"
echo "   - aksClusterName: '$AKS_NAME'"
echo "   - aksResourceGroup: '$RESOURCE_GROUP'"
echo ""
echo "2. Create service connections in Azure DevOps:"
echo "   - ACR Service Connection pointing to: $ACR_LOGIN_SERVER"
echo "   - AKS Service Connection for cluster: $AKS_NAME"
echo ""
echo "3. Test your setup:"
echo "   kubectl get nodes"
echo "   az acr login --name $ACR_NAME"
echo ""

print_status "Setup completed successfully! 🎉"