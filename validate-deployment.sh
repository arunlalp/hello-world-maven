#!/bin/bash

# Deployment Validation Script
# This script helps validate that the application is deployed correctly

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
NAMESPACE="default"
RELEASE_NAME="hello-world-maven"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-n namespace] [-r release-name]"
            echo "Options:"
            echo "  -n, --namespace    Kubernetes namespace (default: default)"
            echo "  -r, --release      Helm release name (default: hello-world-maven)"
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            exit 1
            ;;
    esac
done

print_header "Validating Hello World Maven Deployment"

# Check if kubectl is available and configured
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_warning "Helm is not installed. Some checks will be skipped."
    HELM_AVAILABLE=false
else
    HELM_AVAILABLE=true
fi

print_status "Using namespace: $NAMESPACE"
print_status "Using release name: $RELEASE_NAME"
echo ""

# Check Helm release status
if [[ "$HELM_AVAILABLE" == "true" ]]; then
    print_header "Helm Release Status"
    if helm status "$RELEASE_NAME" -n "$NAMESPACE" &> /dev/null; then
        helm status "$RELEASE_NAME" -n "$NAMESPACE"
        print_status "Helm release is deployed"
    else
        print_error "Helm release '$RELEASE_NAME' not found in namespace '$NAMESPACE'"
    fi
    echo ""
fi

# Check pods
print_header "Pod Status"
if pods=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=hello-world-maven -o json 2>/dev/null); then
    pod_count=$(echo "$pods" | jq -r '.items | length')
    if [[ $pod_count -eq 0 ]]; then
        print_error "No pods found with label app.kubernetes.io/name=hello-world-maven"
    else
        print_status "Found $pod_count pod(s)"
        kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=hello-world-maven
        
        # Check if pods are ready
        ready_pods=$(echo "$pods" | jq -r '.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True")) | .metadata.name' | wc -l)
        print_status "$ready_pods out of $pod_count pods are ready"
        
        if [[ $ready_pods -lt $pod_count ]]; then
            print_warning "Not all pods are ready. Checking pod details..."
            kubectl describe pods -n "$NAMESPACE" -l app.kubernetes.io/name=hello-world-maven | grep -A 5 "Events:"
        fi
    fi
else
    print_error "Failed to get pods"
fi
echo ""

# Check services
print_header "Service Status"
service_name="${RELEASE_NAME}-hello-world-maven"
if kubectl get svc "$service_name" -n "$NAMESPACE" &> /dev/null; then
    kubectl get svc "$service_name" -n "$NAMESPACE"
    
    # Get service type and external access info
    service_type=$(kubectl get svc "$service_name" -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    print_status "Service type: $service_type"
    
    if [[ "$service_type" == "LoadBalancer" ]]; then
        external_ip=$(kubectl get svc "$service_name" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [[ -n "$external_ip" && "$external_ip" != "null" ]]; then
            print_status "External IP: $external_ip"
            print_status "Application URL: http://$external_ip"
        else
            print_warning "LoadBalancer external IP is still pending"
        fi
    elif [[ "$service_type" == "NodePort" ]]; then
        node_port=$(kubectl get svc "$service_name" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
        print_status "NodePort: $node_port"
    fi
else
    print_error "Service '$service_name' not found in namespace '$NAMESPACE'"
fi
echo ""

# Check ingress (if exists)
print_header "Ingress Status"
ingress_name="${RELEASE_NAME}-hello-world-maven"
if kubectl get ingress "$ingress_name" -n "$NAMESPACE" &> /dev/null; then
    kubectl get ingress "$ingress_name" -n "$NAMESPACE"
    hosts=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[*].host}')
    if [[ -n "$hosts" ]]; then
        print_status "Ingress hosts: $hosts"
    fi
else
    print_status "No ingress found (this is normal if ingress is not enabled)"
fi
echo ""

# Test application connectivity
print_header "Application Connectivity Test"
print_status "Testing application endpoints..."

# Port forward for testing
kubectl port-forward "svc/$service_name" 8080:80 -n "$NAMESPACE" &
PF_PID=$!
sleep 3

# Function to cleanup port-forward
cleanup() {
    if [[ -n "$PF_PID" ]]; then
        kill $PF_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Test root endpoint
if curl -s --connect-timeout 5 http://localhost:8080 > /dev/null; then
    root_response=$(curl -s http://localhost:8080)
    print_status "✅ Root endpoint (/) is accessible"
    echo "   Response: $root_response"
else
    print_error "❌ Root endpoint (/) is not accessible"
fi

# Test hello endpoint
if curl -s --connect-timeout 5 http://localhost:8080/hello > /dev/null; then
    hello_response=$(curl -s http://localhost:8080/hello)
    print_status "✅ Hello endpoint (/hello) is accessible" 
    echo "   Response: $hello_response"
else
    print_error "❌ Hello endpoint (/hello) is not accessible"
fi

# Test metrics endpoint
if curl -s --connect-timeout 5 http://localhost:8080/metrics > /dev/null; then
    print_status "✅ Metrics endpoint (/metrics) is accessible"
    metrics_lines=$(curl -s http://localhost:8080/metrics | wc -l)
    echo "   Metrics lines: $metrics_lines"
else
    print_error "❌ Metrics endpoint (/metrics) is not accessible"
fi

echo ""

# Check resource usage
print_header "Resource Usage"
if kubectl top pods -n "$NAMESPACE" -l app.kubernetes.io/name=hello-world-maven &> /dev/null; then
    kubectl top pods -n "$NAMESPACE" -l app.kubernetes.io/name=hello-world-maven
else
    print_warning "Resource metrics not available (metrics-server may not be installed)"
fi
echo ""

# Summary
print_header "Validation Summary"
print_status "Deployment validation completed"
print_status "For detailed logs, run: kubectl logs -l app.kubernetes.io/name=hello-world-maven -n $NAMESPACE"
print_status "To access the application locally: kubectl port-forward svc/$service_name 8080:80 -n $NAMESPACE"

cleanup