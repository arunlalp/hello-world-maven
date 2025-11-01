#!/bin/bash

# GitHub Branch Protection Setup Script
# This script configures branch protection rules for security

# Configuration
OWNER="your-github-username"  # Replace with your GitHub username/org
REPO="hello-world-maven"       # Replace with your repository name
BRANCH="main"                 # Main branch to protect
TOKEN="${GITHUB_TOKEN}"       # Set your GitHub personal access token

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔒 Setting up GitHub Branch Protection Rules${NC}"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed. Please install it first.${NC}"
    echo "Install instructions: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub. Please run 'gh auth login' first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Configuring branch protection for ${OWNER}/${REPO}:${BRANCH}${NC}"

# Create branch protection rule
gh api \
  --method PUT \
  -H "Accept: application/vnd.github.v3+json" \
  "/repos/${OWNER}/${REPO}/branches/${BRANCH}/protection" \
  --input - << EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Security Analysis",
      "Code Quality and Coverage", 
      "continuous-integration/azure-pipelines",
      "PR Security Summary"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "bypass_pull_request_allowances": {
      "users": [],
      "teams": []
    }
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Branch protection rules configured successfully!${NC}"
    
    echo -e "\n${GREEN}📋 Summary of protection rules:${NC}"
    echo "  ✅ Required status checks (strict)"
    echo "  ✅ 2 required approving reviews"
    echo "  ✅ Dismiss stale reviews when new commits are pushed"
    echo "  ✅ Require review from code owners"
    echo "  ✅ Admin enforcement enabled"
    echo "  ✅ Require conversation resolution"
    echo "  ✅ Block force pushes and deletions"
    
    echo -e "\n${YELLOW}📝 Next steps:${NC}"
    echo "1. Create a CODEOWNERS file to specify security team reviews"
    echo "2. Configure security team notifications"
    echo "3. Set up Azure DevOps service connection"
    echo "4. Run a test PR to verify the security checks"
    
else
    echo -e "${RED}❌ Failed to configure branch protection rules${NC}"
    echo "Please check your permissions and repository settings"
    exit 1
fi

# Create CODEOWNERS file if it doesn't exist
if [ ! -f ".github/CODEOWNERS" ]; then
    echo -e "\n${YELLOW}📝 Creating CODEOWNERS file...${NC}"
    
    mkdir -p .github
    cat > .github/CODEOWNERS << 'EOF'
# Global code owners
* @security-team @devops-team

# Security-sensitive files require security team review
SECURITY.md @security-team
azure-pipelines.yml @security-team @devops-team
.github/workflows/ @security-team @devops-team
*/Dockerfile @security-team @devops-team
*/helm-chart/ @security-team @devops-team

# Infrastructure and deployment configurations
*.yaml @devops-team
*.yml @devops-team
helm-chart/ @devops-team @security-team

# Security policies and configurations
dependency-check-suppressions.xml @security-team
.trivyignore @security-team

# Build and dependency files
pom.xml @security-team
package.json @security-team
requirements.txt @security-team
EOF
    
    echo -e "${GREEN}✅ CODEOWNERS file created${NC}"
else
    echo -e "${YELLOW}📝 CODEOWNERS file already exists${NC}"
fi

echo -e "\n${GREEN}🎉 Security configuration completed!${NC}"
echo -e "Repository: https://github.com/${OWNER}/${REPO}"
echo -e "Branch protection: https://github.com/${OWNER}/${REPO}/settings/branch_protection_rules"