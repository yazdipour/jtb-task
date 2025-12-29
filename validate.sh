#!/bin/bash
# Validation script for code quality checks
# This script runs various linters and validators to ensure code quality
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Print colored output
print_status() {
    local status=$1
    local message=$2
    
    if [[ "${status}" == "PASS" ]]; then
        echo -e "${GREEN}✓${NC} ${message}"
        ((PASSED++))
    elif [[ "${status}" == "FAIL" ]]; then
        echo -e "${RED}✗${NC} ${message}"
        ((FAILED++))
    elif [[ "${status}" == "SKIP" ]]; then
        echo -e "${YELLOW}⊘${NC} ${message}"
    else
        echo "  ${message}"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Run shellcheck on bash scripts
check_shellcheck() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking Bash Scripts (ShellCheck)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! command_exists shellcheck; then
        print_status "SKIP" "ShellCheck not installed"
        return 0
    fi
    
    local failed=0
    for script in scripts/*.sh test.sh; do
        if [[ -f "${script}" ]]; then
            if shellcheck "${script}"; then
                print_status "PASS" "${script}"
            else
                print_status "FAIL" "${script}"
                failed=1
            fi
        fi
    done
    
    return ${failed}
}

# Check bash script permissions
check_script_permissions() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking Script Permissions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local failed=0
    for script in scripts/*.sh test.sh; do
        if [[ -f "${script}" ]]; then
            if [[ -x "${script}" ]]; then
                print_status "PASS" "${script} is executable"
            else
                print_status "FAIL" "${script} is not executable"
                failed=1
            fi
        fi
    done
    
    return ${failed}
}

# Validate TeamCity Kotlin DSL files
check_teamcity_dsl() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking TeamCity Kotlin DSL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local failed=0
    
    # Check for package declarations
    for kt_file in .teamcity/*.kt .teamcity/*.kts; do
        if [[ -f "${kt_file}" ]]; then
            if grep -q "^package _Self" "${kt_file}" || grep -q "^import" "${kt_file}"; then
                print_status "PASS" "${kt_file} has proper structure"
            else
                print_status "FAIL" "${kt_file} missing package/import declarations"
                failed=1
            fi
        fi
    done
    
    # Check if settings.kts exists
    if [[ -f ".teamcity/settings.kts" ]]; then
        print_status "PASS" "settings.kts exists"
    else
        print_status "FAIL" "settings.kts not found"
        failed=1
    fi
    
    return ${failed}
}

# Check Maven configuration
check_maven_config() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking Maven Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local failed=0
    
    # Check for reproducibility timestamp
    if grep -q "project.build.outputTimestamp" pom.xml; then
        print_status "PASS" "project.build.outputTimestamp configured"
    else
        print_status "FAIL" "project.build.outputTimestamp not configured"
        failed=1
    fi
    
    # Check for Javadoc plugin
    if grep -q "maven-javadoc-plugin" pom.xml; then
        print_status "PASS" "maven-javadoc-plugin configured"
    else
        print_status "FAIL" "maven-javadoc-plugin not configured"
        failed=1
    fi
    
    return ${failed}
}

# Check Docker configuration
check_docker_config() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking Docker Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local failed=0
    
    # Check Dockerfile exists
    if [[ -f "Dockerfile" ]]; then
        print_status "PASS" "Dockerfile exists"
    else
        print_status "FAIL" "Dockerfile not found"
        failed=1
    fi
    
    # Check docker-compose.yml exists
    if [[ -f "docker-compose.yml" ]]; then
        print_status "PASS" "docker-compose.yml exists"
    else
        print_status "FAIL" "docker-compose.yml not found"
        failed=1
    fi
    
    return ${failed}
}

# Check documentation
check_documentation() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking Documentation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local failed=0
    
    # Required documentation files
    local required_docs=("README.md" "CONTRIBUTING.md" "task.txt")
    
    for doc in "${required_docs[@]}"; do
        if [[ -f "${doc}" ]]; then
            print_status "PASS" "${doc} exists"
        else
            print_status "FAIL" "${doc} not found"
            failed=1
        fi
    done
    
    # Check README has key sections
    if grep -q "## Quick Start" README.md && \
       grep -q "## How Reproducibility Works" README.md && \
       grep -q "## Troubleshooting" README.md; then
        print_status "PASS" "README.md has required sections"
    else
        print_status "FAIL" "README.md missing required sections"
        failed=1
    fi
    
    return ${failed}
}

# Check .gitignore
check_gitignore() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking .gitignore"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local failed=0
    
    # Check for important ignores
    local required_ignores=("target/" "*.class" "release-notes/" "docs.tar.gz" ".archive-staging/")
    
    for ignore in "${required_ignores[@]}"; do
        if grep -q "${ignore}" .gitignore; then
            print_status "PASS" ".gitignore includes ${ignore}"
        else
            print_status "FAIL" ".gitignore missing ${ignore}"
            failed=1
        fi
    done
    
    return ${failed}
}

# Run all checks
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Code Quality Validation Script      ║"
    echo "╚════════════════════════════════════════╝"
    
    local overall_status=0
    
    check_shellcheck || overall_status=1
    check_script_permissions || overall_status=1
    check_teamcity_dsl || overall_status=1
    check_maven_config || overall_status=1
    check_docker_config || overall_status=1
    check_documentation || overall_status=1
    check_gitignore || overall_status=1
    
    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Passed: ${PASSED}${NC}"
    
    if [[ ${FAILED} -gt 0 ]]; then
        echo -e "${RED}Failed: ${FAILED}${NC}"
    fi
    
    echo ""
    
    if [[ ${overall_status} -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
    else
        echo -e "${RED}✗ Some checks failed!${NC}"
    fi
    
    echo ""
    
    exit ${overall_status}
}

# Run main function
main "$@"
