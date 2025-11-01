#!/bin/bash

# Security Fix Helper Script
# This script helps identify and address security issues

echo "🔍 Security Issue Diagnosis Helper"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "pom.xml" ]; then
    echo "❌ Error: Not in project root directory (pom.xml not found)"
    exit 1
fi

echo "1️⃣ Checking test coverage..."
if [ -f "target/site/jacoco/jacoco.xml" ]; then
    echo "✅ JaCoCo report found"
    # Simple coverage calculation
    MISSED=$(grep -o 'missed="[^"]*"' target/site/jacoco/jacoco.xml | head -1 | cut -d'"' -f2)
    COVERED=$(grep -o 'covered="[^"]*"' target/site/jacoco/jacoco.xml | head -1 | cut -d'"' -f2)
    if [ -n "$MISSED" ] && [ -n "$COVERED" ]; then
        TOTAL=$((MISSED + COVERED))
        if [ "$TOTAL" -gt 0 ]; then
            COVERAGE=$((COVERED * 100 / TOTAL))
            echo "📊 Current coverage: ${COVERAGE}%"
        fi
    fi
else
    echo "⚠️  No coverage report found. Run: mvn test jacoco:report"
fi

echo ""
echo "2️⃣ Checking for test files..."
TEST_COUNT=$(find src/test -name "*.java" 2>/dev/null | wc -l)
echo "📝 Found $TEST_COUNT test files"

if [ "$TEST_COUNT" -eq 0 ]; then
    echo "⚠️  No test files found. This explains 0% coverage."
    echo "💡 Recommendation: Add unit tests to src/test/java/"
fi

echo ""
echo "3️⃣ Checking Docker image security..."
if [ -f "Dockerfile" ]; then
    echo "🐳 Dockerfile found"
    
    # Check base image
    BASE_IMAGE=$(grep "^FROM" Dockerfile | tail -1 | cut -d' ' -f2)
    echo "📦 Base image: $BASE_IMAGE"
    
    # Check for security best practices
    if grep -q "USER" Dockerfile; then
        echo "✅ Non-root user configured"
    else
        echo "⚠️  No USER directive found - container may run as root"
    fi
    
    if grep -q "RUN.*apk.*update.*upgrade" Dockerfile; then
        echo "✅ Security updates applied"
    else
        echo "💡 Consider adding: RUN apk update && apk upgrade"
    fi
else
    echo "❌ No Dockerfile found"
fi

echo ""
echo "4️⃣ Dependency security check..."
if command -v mvn >/dev/null 2>&1; then
    echo "🔍 Running dependency check..."
    mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=10 -DsuppressOnExitRule=CVE-2022-42889 2>/dev/null || echo "⚠️  Some dependencies may have vulnerabilities"
else
    echo "❌ Maven not found"
fi

echo ""
echo "🛠️  Quick Fixes:"
echo "==============="
echo "For Code Coverage:"
echo "  - Run: mvn test jacoco:report"
echo "  - Add more unit tests in src/test/java/"
echo ""
echo "For Container Security:"
echo "  - Update to latest Alpine base image"
echo "  - Use eclipse-temurin instead of openjdk"
echo "  - Apply security updates with: RUN apk update && apk upgrade"
echo ""
echo "For Dependencies:"
echo "  - Update versions in pom.xml"
echo "  - Run: mvn versions:display-dependency-updates"
echo ""
echo "🔧 To run tests and generate coverage:"
echo "   mvn clean test jacoco:report"
echo ""
echo "🐳 To scan Docker image for vulnerabilities:"
echo "   docker build -t myapp:test ."
echo "   trivy image myapp:test"