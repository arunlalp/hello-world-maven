# Security Configuration Guide

This document outlines the comprehensive security measures implemented in this CI/CD pipeline and deployment configuration.

## Table of Contents

1. [Pipeline Security](#pipeline-security)
2. [Container Security](#container-security)
3. [Runtime Security](#runtime-security)
4. [Branch Protection & PR Security](#branch-protection--pr-security)
5. [Monitoring & Alerting](#monitoring--alerting)
6. [Incident Response](#incident-response)
7. [Security Best Practices](#security-best-practices)
8. [Compliance](#compliance)

## Pipeline Security

### Static Application Security Testing (SAST)

The pipeline includes multiple layers of security scanning:

#### Code Analysis
- **CodeQL Analysis**: GitHub's semantic code analysis engine scans for security vulnerabilities
- **SonarCloud Integration**: Ready for static code analysis (uncomment in pipeline)
- **Secret Scanning**: TruffleHog scans for exposed secrets and credentials

#### Dependency Scanning
- **OWASP Dependency Check**: Scans all dependencies for known vulnerabilities
- **Maven Security Audit**: Additional dependency vulnerability checking
- **License Compliance**: Ensures all dependencies have compatible licenses

#### Configuration
```yaml
# Security thresholds in azure-pipelines.yml
MAX_CRITICAL_VULNERABILITIES: 0
MAX_HIGH_VULNERABILITIES: 5
MIN_CODE_COVERAGE: 80
```

### Security Gates

The pipeline implements security gates that prevent insecure code from being deployed:

1. **Critical Vulnerability Gate**: Fails build if critical vulnerabilities are found
2. **High Vulnerability Threshold**: Allows up to 5 high-severity vulnerabilities
3. **Code Coverage Gate**: Requires minimum 80% test coverage
4. **Secret Detection**: Fails if secrets are detected in code

## Container Security

### Build-time Security

#### Dockerfile Security Best Practices
- Multi-stage build to reduce attack surface
- Non-root user (UID 1000) for runtime security
- Minimal base image (openjdk:11-jre-slim)
- No secrets in image layers
- Explicit dependency copying

#### Container Scanning
- **Trivy Scanner**: Scans container images for vulnerabilities
- **Automated Scanning**: Runs on every image build
- **Security Reporting**: Generates SARIF reports for GitHub Security tab

### Runtime Security

#### Pod Security Context
```yaml
podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true
  runAsUser: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
```

#### Resource Limits
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
```

## Runtime Security

### Network Security

#### Network Policies
- **Ingress Control**: Only allows traffic from same namespace and ingress controllers
- **Egress Control**: Restricts outbound traffic to DNS, HTTPS, and Kubernetes API
- **Pod-to-Pod Communication**: Controlled through namespace selectors

#### Service Account Security
- **Dedicated Service Account**: Each deployment uses its own service account
- **Token Auto-mounting**: Disabled by default (`automountServiceAccountToken: false`)
- **RBAC**: Minimal permissions through role-based access control

### Pod Security Standards

#### Pod Security Policies (PSP)
- **No Privileged Containers**: Prevents privilege escalation
- **Required Security Context**: Enforces non-root execution
- **Capability Dropping**: Removes all Linux capabilities
- **Read-only Root Filesystem**: Prevents runtime modifications

#### Pod Disruption Budgets
- Ensures at least one pod is always available during updates
- Prevents complete service outages during maintenance

## Branch Protection & PR Security

### GitHub Branch Protection Rules

**Recommended settings for main branch:**

```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Security Analysis",
      "Code Quality and Coverage",
      "continuous-integration/azure-pipelines"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null
}
```

### PR Security Automation

#### Automated Security Checks
- **Secret Scanning**: TruffleHog scans PR changes
- **Dependency Analysis**: OWASP checks for new vulnerabilities
- **Container Scanning**: Trivy scans if Dockerfile changes
- **Code Coverage**: Ensures tests maintain coverage thresholds

#### Security Review Template
The PR template includes comprehensive security checklists:
- Code security verification
- Dependency security review
- Container security validation
- Infrastructure security confirmation

## Monitoring & Alerting

### Security Monitoring

#### Application Monitoring
- **Prometheus Metrics**: Application performance and health metrics
- **Health Checks**: Liveness and readiness probes
- **Service Monitoring**: Automatic ServiceMonitor creation

#### Security Event Monitoring
```yaml
# Enable audit logging in AKS cluster
kubectl patch configmap audit-policy -n kube-system --patch '
data:
  audit-policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    - level: Metadata
      namespaces: ["default"]
      verbs: ["create", "delete", "patch"]
'
```

### Alert Configuration

#### Critical Alerts
- Container image vulnerabilities
- Pod security policy violations
- Network policy violations
- Resource limit breaches

#### Setup Instructions
1. Configure Azure Monitor for AKS
2. Set up Log Analytics workspace
3. Create alert rules for security events
4. Configure notification channels

## Incident Response

### Security Incident Response Plan

#### 1. Detection
- **Automated Detection**: Pipeline failures, security scan alerts
- **Manual Detection**: Security team reviews, vulnerability reports

#### 2. Assessment
- Evaluate severity and impact
- Determine if incident is ongoing
- Identify affected systems and data

#### 3. Containment
- **Immediate Actions**:
  ```bash
  # Scale down affected deployment
  kubectl scale deployment hello-world-maven --replicas=0
  
  # Block network traffic if needed
  kubectl apply -f emergency-netpol.yaml
  
  # Rotate secrets
  kubectl delete secret acr-secret
  kubectl create secret docker-registry acr-secret --docker-server=... --docker-username=... --docker-password=...
  ```

#### 4. Eradication & Recovery
- Apply security patches
- Update vulnerable dependencies
- Rebuild and redeploy containers
- Verify fixes through security scans

#### 5. Post-Incident
- Document lessons learned
- Update security configurations
- Improve monitoring and detection

### Emergency Contacts
```yaml
# Add to your organization's documentation
security_team:
  email: security@yourorg.com
  slack: #security-incidents
  phone: +1-XXX-XXX-XXXX

devops_team:
  email: devops@yourorg.com
  slack: #devops-alerts
  phone: +1-XXX-XXX-XXXX
```

## Security Best Practices

### Development Guidelines

#### Secure Coding Practices
1. **Input Validation**: Validate all user inputs
2. **Error Handling**: Don't expose sensitive information in errors
3. **Authentication**: Use strong authentication mechanisms
4. **Authorization**: Implement least-privilege access
5. **Logging**: Log security events without sensitive data

#### Secret Management
```bash
# Use Azure Key Vault for secrets
az keyvault secret set --vault-name MyKeyVault --name db-password --value "MySecretPassword"

# Reference secrets in Kubernetes
kubectl create secret generic app-secrets \
  --from-literal=database-url="$(az keyvault secret show --name db-url --vault-name MyKeyVault --query value -o tsv)"
```

### Infrastructure Security

#### AKS Cluster Hardening
```bash
# Enable Azure Policy for AKS
az aks enable-addons --addons azure-policy --name myAKSCluster --resource-group myResourceGroup

# Enable network policies
az aks update --name myAKSCluster --resource-group myResourceGroup --network-policy calico

# Enable pod security standards
kubectl apply -f https://raw.githubusercontent.com/kubernetes/pod-security-admission/release-1.25/pod-security-admission.yaml
```

### Container Registry Security
```bash
# Enable vulnerability scanning in ACR
az acr config content-trust update --registry myregistry --status enabled

# Enable quarantine policy
az acr config content-trust show --registry myregistry
```

## Compliance

### Regulatory Compliance

#### SOC 2 Compliance
- Audit logging enabled
- Access controls implemented
- Monitoring and alerting configured
- Incident response procedures documented

#### GDPR Compliance
- No PII in application logs
- Data encryption in transit and at rest
- Right to be forgotten implementation ready

### Security Frameworks

#### NIST Cybersecurity Framework
- **Identify**: Asset inventory and risk assessment
- **Protect**: Security controls and awareness
- **Detect**: Monitoring and anomaly detection
- **Respond**: Incident response procedures
- **Recover**: Business continuity planning

#### CIS Controls
- Inventory and control of enterprise assets
- Inventory and control of software assets
- Data protection and secure configuration
- Access control management
- Security awareness and training

## Security Testing

### Testing Strategy

#### Unit Tests
```java
// Example security-focused unit test
@Test
public void testInputValidation() {
    String maliciousInput = "<script>alert('xss')</script>";
    String sanitized = inputValidator.sanitize(maliciousInput);
    assertFalse(sanitized.contains("<script>"));
}
```

#### Integration Tests
```bash
# Security integration testing
mvn test -Dtest=SecurityIntegrationTest
```

#### Penetration Testing
- Schedule regular pen tests
- Test both application and infrastructure
- Document and remediate findings

## Configuration Management

### Security Configuration as Code

All security configurations are version-controlled and automatically deployed:

- **Pipeline Security**: `azure-pipelines.yml`
- **Container Security**: `Dockerfile`
- **Kubernetes Security**: Helm templates
- **Network Security**: NetworkPolicy manifests
- **Access Control**: RBAC configurations

### Security Scanning Configuration

#### OWASP Dependency Check
```xml
<!-- pom.xml configuration -->
<plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <configuration>
        <suppressionFile>dependency-check-suppressions.xml</suppressionFile>
        <failBuildOnCVSS>7</failBuildOnCVSS>
    </configuration>
</plugin>
```

#### Trivy Configuration
```yaml
# .trivyignore file for false positives
CVE-2021-44228  # Log4j vulnerability (not applicable to our app)
```

This security configuration provides comprehensive protection across the entire application lifecycle, from development through deployment and runtime operations.