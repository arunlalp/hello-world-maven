# Ignore Files Documentation

This document provides an overview of all ignore files configured in this project and their purposes.

## Overview

This project uses multiple ignore files to control which files are excluded from various operations like version control, Docker builds, Helm packaging, and cloud deployments.

## Ignore Files Reference

### 1. `.gitignore` (Root & Project Level)

**Locations:**
- `/hello-world-maven/.gitignore` (Root)
- `/hello-world-maven/hello-world-maven/.gitignore` (Project)

**Purpose:** Controls which files are excluded from Git version control.

**Key Exclusions:**
- Compiled files (*.class, *.jar)
- Build outputs (target/, build/)
- IDE files (.idea/, .vscode/, *.iml)
- OS files (.DS_Store, Thumbs.db)
- Test reports and coverage (jacoco.xml, surefire-reports/)
- Logs (*.log, logs/)
- Secrets and credentials (*.pem, *.key, *.jks)
- Environment files (.env, application-local.yml)
- Cache directories (.m2/repository/)
- Temporary files (*.tmp, *.temp, *.bak)

**Best Practices:**
- Never commit sensitive data (passwords, API keys, certificates)
- Keep environment-specific configs out of version control
- Use templates (e.g., `.env.example`) for configuration examples

---

### 2. `.dockerignore`

**Location:** `/hello-world-maven/hello-world-maven/.dockerignore`

**Purpose:** Controls which files are excluded from Docker build context, reducing image size and build time.

**Key Exclusions:**
- Git files (.git/, .gitignore)
- IDE files and configurations
- Test files (src/test/, surefire-reports/)
- Documentation (*.md, docs/)
- CI/CD configurations (azure-pipelines.yml, Jenkinsfile)
- Development scripts (*.sh, except docker-entrypoint.sh)
- Helm charts
- Security scanning files
- Build artifacts (except final JAR/WAR)

**Best Practices:**
- Minimize Docker build context for faster builds
- Exclude test files from production images
- Keep only runtime-necessary files
- Document any included scripts

---

### 3. `.trivyignore`

**Location:** `/hello-world-maven/hello-world-maven/.trivyignore`

**Purpose:** Specifies CVEs (Common Vulnerabilities and Exposures) to ignore during Trivy security scans.

**Structure:**
- Alpine Base Image Vulnerabilities
- OpenJDK/JRE Vulnerabilities
- Third-Party Library Vulnerabilities
- Known False Positives
- Accepted Risks (requires management approval)

**Best Practices:**
- **IMPORTANT:** Only add entries after security review
- Document why each CVE is acceptable
- Include date added and added by whom
- Review monthly and remove outdated entries
- Never ignore Critical/High severity without approval
- Keep a separate security register for audit

**Format:**
```
CVE-YYYY-NNNN  # Reason, date added, review date
```

---

### 4. `.helmignore`

**Location:** `/hello-world-maven/hello-world-maven/helm-chart/.helmignore`

**Purpose:** Controls which files are excluded when packaging Helm charts.

**Key Exclusions:**
- Version control files (.git/, .svn/)
- IDE files
- OS generated files
- CI/CD configurations
- Documentation (except Chart README)
- Development and testing files
- Backup files
- Scripts
- Chart development files (values-local.yaml, values-dev.yaml)

**Best Practices:**
- Keep Helm packages minimal
- Exclude development-specific values files
- Include only production templates
- Document chart with README.md

---

### 5. `.gcloudignore`

**Location:** `/hello-world-maven/hello-world-maven/.gcloudignore`

**Purpose:** Controls which files are excluded when deploying to Google Cloud Platform.

**Key Exclusions:**
- Version control files
- IDE configurations
- Test files and reports
- Documentation
- CI/CD configurations
- Docker and Kubernetes files
- Scripts (except startup scripts)
- Security scanning files
- Development environment files

**Best Practices:**
- Similar to .dockerignore but for GCP deployments
- Include only runtime-necessary files
- Exclude all development and testing artifacts

---

### 6. `.npmignore`

**Location:** `/hello-world-maven/hello-world-maven/.npmignore`

**Purpose:** Specifies files to exclude when publishing to npm registry (if applicable).

**Key Exclusions:**
- Source files (if only distributing built artifacts)
- Test files
- Build tools and CI/CD configs
- IDE files
- Documentation (except README, CHANGELOG, LICENSE)
- Configuration files
- Docker files
- Maven/Java files (if mixed project)

**Best Practices:**
- Keep published packages minimal
- Include only necessary files for package consumers
- Always include README and LICENSE

---

## File Hierarchy and Relationships

```
hello-world-maven/
├── .gitignore                           # Root-level Git ignore
└── hello-world-maven/
    ├── .gitignore                       # Project-level Git ignore (most comprehensive)
    ├── .dockerignore                    # Docker build context control
    ├── .trivyignore                     # Security scan suppressions
    ├── .gcloudignore                    # GCP deployment control
    ├── .npmignore                       # NPM publish control
    └── helm-chart/
        └── .helmignore                  # Helm packaging control
```

## Maintenance Guidelines

### Regular Review Schedule
- **Weekly:** Review security scan results (.trivyignore)
- **Monthly:** Audit all ignore files for relevance
- **Quarterly:** Update patterns based on new technologies/tools
- **Before Release:** Verify no sensitive data is exposed

### Adding New Patterns
1. Determine which ignore file(s) need updating
2. Add pattern with explanatory comment
3. Test that pattern works as expected
4. Document in this README if significant

### Common Patterns to Watch

#### Development Files
```
*.tmp
*.temp
*.bak
*.swp
*~
demo.txt
TODO.md
NOTES.md
```

#### Secrets (NEVER COMMIT)
```
*.pem
*.key
*.crt
*.p12
*.jks
.env
secrets/
credentials/
```

#### Build Artifacts
```
target/
build/
out/
*.class
*.jar (except final artifacts)
```

## Security Considerations

### Critical Rules
1. **Never commit secrets** - Use environment variables or secret managers
2. **Never ignore security in .trivyignore** without approval
3. **Review .dockerignore** - Don't accidentally include secrets in images
4. **Audit regularly** - Check what files are actually being ignored

### Secret Management
- Use Azure Key Vault, AWS Secrets Manager, or similar
- Use environment variables for runtime secrets
- Use `.env.example` templates without real values
- Rotate secrets regularly

### Compliance
- Document all exceptions in .trivyignore
- Maintain audit log of ignored vulnerabilities
- Review with security team quarterly
- Follow company security policies

## Troubleshooting

### Git still tracking ignored files?
```bash
# Clear Git cache and re-add files
git rm -r --cached .
git add .
git commit -m "Update .gitignore"
```

### Docker build including unwanted files?
```bash
# Check what's in build context
docker build --no-cache -t test . --progress=plain

# List files being sent to Docker daemon
DOCKER_BUILDKIT=1 docker build --no-cache -t test . 2>&1 | grep "transferring context"
```

### Helm chart including extra files?
```bash
# Check packaged chart contents
helm package ./helm-chart
tar -tzf <chart-name>-<version>.tgz
```

### Finding large ignored files
```bash
# Find large files that might be ignored
find . -type f -size +1M -not -path "./target/*" -not -path "./.git/*"
```

## References

- [Git Documentation - gitignore](https://git-scm.com/docs/gitignore)
- [Docker Documentation - .dockerignore](https://docs.docker.com/engine/reference/builder/#dockerignore-file)
- [Helm Documentation - .helmignore](https://helm.sh/docs/chart_template_guide/helm_ignore_file/)
- [Trivy Documentation - .trivyignore](https://aquasecurity.github.io/trivy/latest/docs/configuration/filtering/)
- [Google Cloud - .gcloudignore](https://cloud.google.com/sdk/gcloud/reference/topic/gcloudignore)

## Version History

- **2025-11-01:** Initial comprehensive setup
  - Created/updated all ignore files
  - Standardized patterns across files
  - Added detailed documentation
  - Implemented security best practices

---

**Last Updated:** November 1, 2025  
**Maintained By:** Development Team  
**Review Frequency:** Monthly
