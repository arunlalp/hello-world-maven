#!/bin/bash

# Test script to verify Trivy report handling
echo "🧪 Testing Trivy report handling logic..."

# Create test directory structure
mkdir -p test-container-security-reports

# Test 1: Empty report
echo "Test 1: Creating empty report..."
echo '{"Results":[],"SchemaVersion":2}' > test-container-security-reports/trivy-report.json

# Test the vulnerability counting logic
REPORT_FILE="test-container-security-reports/trivy-report.json"

if [ ! -f "$REPORT_FILE" ]; then
  echo "⚠️ Trivy report not found at $REPORT_FILE"
  CRITICAL_COUNT=0
  HIGH_COUNT=0
  MEDIUM_COUNT=0
else
  CRITICAL_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
  HIGH_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
  MEDIUM_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
fi

echo "Empty report results:"
echo "  Critical: $CRITICAL_COUNT"
echo "  High: $HIGH_COUNT" 
echo "  Medium: $MEDIUM_COUNT"

# Test 2: Report with vulnerabilities
echo ""
echo "Test 2: Creating report with sample vulnerabilities..."
cat > test-container-security-reports/trivy-report-with-vulns.json << 'EOF'
{
  "Results": [
    {
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2023-1234",
          "Severity": "CRITICAL",
          "Title": "Sample Critical Vulnerability",
          "PkgName": "test-package"
        },
        {
          "VulnerabilityID": "CVE-2023-5678",
          "Severity": "HIGH", 
          "Title": "Sample High Vulnerability",
          "PkgName": "another-package"
        },
        {
          "VulnerabilityID": "CVE-2023-9999",
          "Severity": "MEDIUM",
          "Title": "Sample Medium Vulnerability", 
          "PkgName": "third-package"
        }
      ]
    }
  ],
  "SchemaVersion": 2
}
EOF

REPORT_FILE="test-container-security-reports/trivy-report-with-vulns.json"
CRITICAL_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
HIGH_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
MEDIUM_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$REPORT_FILE" 2>/dev/null || echo "0")

echo "Report with vulnerabilities results:"
echo "  Critical: $CRITICAL_COUNT"
echo "  High: $HIGH_COUNT"
echo "  Medium: $MEDIUM_COUNT"

# Test vulnerability details extraction
if [ "$CRITICAL_COUNT" -gt "0" ] && [ -f "$REPORT_FILE" ]; then
  echo ""
  echo "Critical vulnerability details:"
  jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL") | "CVE: \(.VulnerabilityID) - \(.Title) - Package: \(.PkgName)"' "$REPORT_FILE" 2>/dev/null || echo "Could not parse critical vulnerabilities"
fi

# Cleanup
rm -rf test-container-security-reports

echo ""
echo "✅ Trivy report handling tests completed"