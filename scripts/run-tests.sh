#!/bin/bash

# ================================================================================
# 🧪 Infrastructure Testing Script
# 👨‍💻 Author: Kleilson Santos
# 📅 Created: 2025-11-07
#
# 🎯 Comprehensive testing script for infrastructure services
# ================================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TIMEOUT=300
REPORT_DIR="src/reports"
COVERAGE_DIR="$REPORT_DIR/coverage"

# Functions
print_banner() {
    echo -e "\n${BLUE}=================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}=================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_banner "CHECKING PREREQUISITES"
    
    # Check if docker-compose is running
    if ! docker compose ps >/dev/null 2>&1; then
        print_error "Docker Compose services not running. Please start with 'make up'"
        exit 1
    fi
    
    # Check if required Python packages are installed
    if ! python3 -c "import pytest" >/dev/null 2>&1; then
        print_error "pytest not installed. Please run 'make install'"
        exit 1
    fi
    
    # Create reports directory
    mkdir -p "$COVERAGE_DIR"
    
    print_success "Prerequisites check passed"
}

wait_for_services() {
    print_banner "WAITING FOR SERVICES TO BE READY"
    
    # Give services time to start up
    print_info "Waiting 30 seconds for services to initialize..."
    sleep 30
    
    # Check critical services are responding
    critical_services=(
        "localhost:5432"  # PostgreSQL
        "localhost:27017" # MongoDB  
        "localhost:3306"  # MySQL
        "localhost:6379"  # Redis
        "localhost:9090"  # Prometheus
    )
    
    for service in "${critical_services[@]}"; do
        host=$(echo "$service" | cut -d':' -f1)
        port=$(echo "$service" | cut -d':' -f2)
        
        if timeout 10 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            print_success "$service is reachable"
        else
            print_warning "$service not reachable (may still be starting)"
        fi
    done
}

run_unit_tests() {
    print_banner "RUNNING UNIT TESTS"
    
    if python3 -m pytest -m "unit" --tb=short -v \
        --junitxml="$COVERAGE_DIR/unit-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Unit tests passed"
        return 0
    else
        print_error "Unit tests failed"
        return 1
    fi
}

run_integration_tests() {
    print_banner "RUNNING INTEGRATION TESTS"
    
    if python3 -m pytest -m "integration and not slow" --tb=short -v \
        --junitxml="$COVERAGE_DIR/integration-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Integration tests passed"
        return 0
    else
        print_error "Integration tests failed"
        return 1
    fi
}

run_database_tests() {
    print_banner "RUNNING DATABASE FUNCTIONALITY TESTS"
    
    if python3 -m pytest -m "database" --tb=short -v \
        --junitxml="$COVERAGE_DIR/database-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Database tests passed"
        return 0
    else
        print_error "Database tests failed"
        return 1
    fi
}

run_web_services_tests() {
    print_banner "RUNNING WEB SERVICES TESTS"
    
    if python3 -m pytest -m "web" --tb=short -v \
        --junitxml="$COVERAGE_DIR/web-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Web services tests passed"
        return 0
    else
        print_error "Web services tests failed"
        return 1
    fi
}

run_security_tests() {
    print_banner "RUNNING SECURITY TESTS"
    
    if python3 -m pytest -m "security" --tb=short -v \
        --junitxml="$COVERAGE_DIR/security-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Security tests passed"
        return 0
    else
        print_error "Security tests failed"
        return 1
    fi
}

run_monitoring_tests() {
    print_banner "RUNNING MONITORING TESTS"
    
    if python3 -m pytest -m "monitoring" --tb=short -v \
        --junitxml="$COVERAGE_DIR/monitoring-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Monitoring tests passed"
        return 0
    else
        print_error "Monitoring tests failed"
        return 1
    fi
}

run_comprehensive_tests() {
    print_banner "RUNNING COMPREHENSIVE TESTS"
    
    if python3 -m pytest -m "comprehensive" --tb=short -v \
        --junitxml="$COVERAGE_DIR/comprehensive-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Comprehensive tests passed"
        return 0
    else
        print_error "Comprehensive tests failed"
        return 1
    fi
}

run_slow_tests() {
    print_banner "RUNNING SLOW/COMPLETE TESTS"
    
    if python3 -m pytest -m "slow" --tb=short -v \
        --junitxml="$COVERAGE_DIR/slow-results.xml" \
        --timeout="$TIMEOUT"; then
        print_success "Slow tests passed"
        return 0
    else
        print_error "Slow tests failed"
        return 1
    fi
}

run_all_tests_with_coverage() {
    print_banner "RUNNING ALL TESTS WITH COVERAGE"
    
    if python3 -m pytest \
        --cov=src \
        --cov-report=html:"$COVERAGE_DIR" \
        --cov-report=xml:"$COVERAGE_DIR/coverage.xml" \
        --cov-report=term-missing \
        --junitxml="$COVERAGE_DIR/all-results.xml" \
        --tb=short -v \
        --timeout="$TIMEOUT"; then
        print_success "All tests with coverage passed"
        return 0
    else
        print_error "Tests with coverage failed"
        return 1
    fi
}

generate_summary_report() {
    print_banner "GENERATING SUMMARY REPORT"
    
    echo "# Infrastructure Testing Summary Report" > "$REPORT_DIR/test-summary.md"
    echo "Generated on: $(date)" >> "$REPORT_DIR/test-summary.md"
    echo "" >> "$REPORT_DIR/test-summary.md"
    
    # Count test results
    if [ -f "$COVERAGE_DIR/all-results.xml" ]; then
        if command -v xmllint >/dev/null 2>&1; then
            tests=$(xmllint --xpath "string(//testsuite/@tests)" "$COVERAGE_DIR/all-results.xml" 2>/dev/null || echo "N/A")
            failures=$(xmllint --xpath "string(//testsuite/@failures)" "$COVERAGE_DIR/all-results.xml" 2>/dev/null || echo "N/A")
            errors=$(xmllint --xpath "string(//testsuite/@errors)" "$COVERAGE_DIR/all-results.xml" 2>/dev/null || echo "N/A")
            
            echo "## Test Results" >> "$REPORT_DIR/test-summary.md"
            echo "- Total Tests: $tests" >> "$REPORT_DIR/test-summary.md"
            echo "- Failures: $failures" >> "$REPORT_DIR/test-summary.md"
            echo "- Errors: $errors" >> "$REPORT_DIR/test-summary.md"
            echo "" >> "$REPORT_DIR/test-summary.md"
        fi
    fi
    
    # Add coverage info if available
    if [ -f "$COVERAGE_DIR/coverage.xml" ]; then
        echo "## Coverage Report" >> "$REPORT_DIR/test-summary.md"
        echo "Coverage report available at: \`$COVERAGE_DIR/index.html\`" >> "$REPORT_DIR/test-summary.md"
        echo "" >> "$REPORT_DIR/test-summary.md"
    fi
    
    print_success "Summary report generated at $REPORT_DIR/test-summary.md"
}

# Main execution
main() {
    local test_type="${1:-all}"
    local exit_code=0
    
    print_banner "INFRASTRUCTURE TESTING SUITE"
    print_info "Test type: $test_type"
    
    check_prerequisites
    wait_for_services
    
    case "$test_type" in
        "unit")
            run_unit_tests || exit_code=1
            ;;
        "integration")
            run_integration_tests || exit_code=1
            ;;
        "database")
            run_database_tests || exit_code=1
            ;;
        "web")
            run_web_services_tests || exit_code=1
            ;;
        "security")
            run_security_tests || exit_code=1
            ;;
        "monitoring")
            run_monitoring_tests || exit_code=1
            ;;
        "comprehensive")
            run_comprehensive_tests || exit_code=1
            ;;
        "slow")
            run_slow_tests || exit_code=1
            ;;
        "coverage")
            run_all_tests_with_coverage || exit_code=1
            ;;
        "quick")
            run_unit_tests || exit_code=1
            run_integration_tests || exit_code=1
            ;;
        "all")
            run_unit_tests || exit_code=1
            run_integration_tests || exit_code=1
            run_database_tests || exit_code=1
            run_web_services_tests || exit_code=1
            run_security_tests || exit_code=1
            run_monitoring_tests || exit_code=1
            run_comprehensive_tests || exit_code=1
            ;;
        "complete")
            run_all_tests_with_coverage || exit_code=1
            ;;
        *)
            print_error "Unknown test type: $test_type"
            echo "Available options: unit, integration, database, web, security, monitoring, comprehensive, slow, coverage, quick, all, complete"
            exit 1
            ;;
    esac
    
    generate_summary_report
    
    if [ $exit_code -eq 0 ]; then
        print_banner "ALL TESTS COMPLETED SUCCESSFULLY! 🎉"
    else
        print_banner "SOME TESTS FAILED! ❌"
    fi
    
    exit $exit_code
}

# Show help
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Infrastructure Testing Script"
    echo ""
    echo "Usage: $0 [test-type]"
    echo ""
    echo "Test types:"
    echo "  unit         - Run only unit tests"
    echo "  integration  - Run integration tests (excluding slow tests)"
    echo "  database     - Run database functionality tests"
    echo "  web          - Run web services tests"
    echo "  security     - Run security and authentication tests"
    echo "  monitoring   - Run monitoring and metrics tests"
    echo "  comprehensive- Run comprehensive infrastructure tests"
    echo "  slow         - Run slow/complete tests"
    echo "  coverage     - Run all tests with coverage report"
    echo "  quick        - Run unit + integration tests only"
    echo "  all          - Run all test categories (default)"
    echo "  complete     - Run all tests with full coverage"
    echo ""
    echo "Examples:"
    echo "  $0 database    # Test only database functionality"
    echo "  $0 quick       # Quick test run"
    echo "  $0 complete    # Full test suite with coverage"
    exit 0
fi

# Execute main function
main "$@"