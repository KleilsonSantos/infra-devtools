#!/bin/bash

# =============================================================================
# 🧪 Infrastructure Professional Testing Suite
# Author: Kleilson Santos  
# Description: Comprehensive testing script for DevOps infrastructure
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PATH="$PROJECT_ROOT/.venv"
PYTHON="$VENV_PATH/bin/python"
PYTEST="$PYTHON -m pytest"
REPORTS_DIR="$PROJECT_ROOT/src/reports"
COVERAGE_DIR="$REPORTS_DIR/coverage"

# Test execution options
DEFAULT_TIMEOUT=300
PARALLEL_JOBS=4

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print section headers
print_section() {
    echo
    print_colored "$BLUE" "============================================================="
    print_colored "$BLUE" "$1"
    print_colored "$BLUE" "============================================================="
}

# Function to check dependencies
check_dependencies() {
    print_section "🔍 Checking Dependencies"
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_colored "$RED" "❌ Docker is not running or not accessible"
        exit 1
    fi
    print_colored "$GREEN" "✅ Docker is running"
    
    # Check if docker-compose is available
    if ! command -v docker-compose >/dev/null 2>&1; then
        print_colored "$RED" "❌ docker-compose is not installed"
        exit 1
    fi
    print_colored "$GREEN" "✅ docker-compose is available"
    
    # Check Python virtual environment
    if [ ! -f "$PYTHON" ]; then
        print_colored "$YELLOW" "⚠️  Python virtual environment not found. Creating..."
        python3 -m venv "$VENV_PATH"
        print_colored "$GREEN" "✅ Virtual environment created"
    else
        print_colored "$GREEN" "✅ Python virtual environment found"
    fi
    
    # Install/upgrade dependencies
    print_colored "$CYAN" "📦 Installing/upgrading Python dependencies..."
    "$VENV_PATH/bin/pip" install --upgrade pip > /dev/null
    "$VENV_PATH/bin/pip" install -r "$PROJECT_ROOT/requirements.txt" > /dev/null
    print_colored "$GREEN" "✅ Dependencies installed"
}

# Function to setup infrastructure
setup_infrastructure() {
    print_section "🚀 Setting Up Infrastructure"
    
    cd "$PROJECT_ROOT"
    
    # Check if services are already running
    if docker-compose ps | grep -q "Up"; then
        print_colored "$YELLOW" "⚠️  Some services are already running"
        read -p "Do you want to restart all services? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_colored "$CYAN" "🔄 Restarting infrastructure..."
            docker-compose down --remove-orphans
            docker-compose up -d
        else
            print_colored "$CYAN" "📋 Using existing infrastructure..."
        fi
    else
        print_colored "$CYAN" "🔄 Starting infrastructure services..."
        docker-compose up -d
    fi
    
    # Wait for services to be ready
    print_colored "$CYAN" "⏳ Waiting for services to be ready..."
    sleep 30
    
    # Check service status
    print_colored "$CYAN" "📊 Service Status:"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    
    print_colored "$GREEN" "✅ Infrastructure setup complete"
}

# Function to create reports directory
setup_reports() {
    print_section "📁 Setting Up Reports Directory"
    
    mkdir -p "$COVERAGE_DIR"
    print_colored "$GREEN" "✅ Reports directory created: $REPORTS_DIR"
}

# Function to run specific test categories
run_test_category() {
    local category=$1
    local description=$2
    local marker=$3
    local timeout=${4:-$DEFAULT_TIMEOUT}
    
    print_section "$description"
    
    local report_file="$REPORTS_DIR/${category}_results.xml"
    local coverage_file="$COVERAGE_DIR/${category}_coverage.xml"
    
    print_colored "$CYAN" "🧪 Running $category tests..."
    
    if $PYTEST \
        -m "$marker" \
        --junitxml="$report_file" \
        --cov=src \
        --cov-report=xml:"$coverage_file" \
        --cov-report=term-missing \
        --timeout="$timeout" \
        -v; then
        print_colored "$GREEN" "✅ $category tests passed"
        return 0
    else
        print_colored "$RED" "❌ $category tests failed"
        return 1
    fi
}

# Function to run all tests with comprehensive reporting
run_comprehensive_tests() {
    print_section "🎯 Running Comprehensive Test Suite"
    
    local overall_report="$REPORTS_DIR/comprehensive_results.xml"
    local overall_coverage="$COVERAGE_DIR/comprehensive_coverage.xml"
    local html_coverage="$COVERAGE_DIR/html"
    
    print_colored "$CYAN" "🧪 Executing full test suite with coverage..."
    
    if $PYTEST \
        --junitxml="$overall_report" \
        --cov=src \
        --cov-report=xml:"$overall_coverage" \
        --cov-report=html:"$html_coverage" \
        --cov-report=term-missing \
        --timeout=600 \
        -v \
        --tb=short \
        -x; then # Stop on first failure for comprehensive tests
        print_colored "$GREEN" "✅ Comprehensive test suite passed"
        return 0
    else
        print_colored "$RED" "❌ Comprehensive test suite failed"
        return 1
    fi
}

# Function to generate test summary report
generate_summary() {
    print_section "📊 Test Execution Summary"
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Count test results from XML reports
    if [ -d "$REPORTS_DIR" ]; then
        for report_file in "$REPORTS_DIR"/*.xml; do
            if [ -f "$report_file" ]; then
                local file_tests=$(grep -o 'tests="[0-9]*"' "$report_file" | grep -o '[0-9]*' | head -1)
                local file_failures=$(grep -o 'failures="[0-9]*"' "$report_file" | grep -o '[0-9]*' | head -1)
                local file_errors=$(grep -o 'errors="[0-9]*"' "$report_file" | grep -o '[0-9]*' | head -1)
                
                if [ -n "$file_tests" ]; then
                    total_tests=$((total_tests + file_tests))
                    local file_failed=$((${file_failures:-0} + ${file_errors:-0}))
                    failed_tests=$((failed_tests + file_failed))
                    passed_tests=$((passed_tests + file_tests - file_failed))
                fi
            fi
        done
    fi
    
    print_colored "$CYAN" "📈 Test Statistics:"
    print_colored "$GREEN" "  ✅ Passed: $passed_tests"
    print_colored "$RED" "  ❌ Failed: $failed_tests"
    print_colored "$BLUE" "  📊 Total: $total_tests"
    
    # Coverage summary
    if [ -f "$COVERAGE_DIR/comprehensive_coverage.xml" ]; then
        local coverage_percent=$(grep -o 'line-rate="[0-9.]*"' "$COVERAGE_DIR/comprehensive_coverage.xml" | head -1 | grep -o '[0-9.]*')
        if [ -n "$coverage_percent" ]; then
            local coverage_int=$(echo "$coverage_percent * 100" | bc -l | cut -d. -f1)
            print_colored "$PURPLE" "  📊 Code Coverage: ${coverage_int}%"
            
            if [ -d "$COVERAGE_DIR/html" ]; then
                print_colored "$CYAN" "  📁 HTML Coverage Report: $COVERAGE_DIR/html/index.html"
            fi
        fi
    fi
    
    # Report locations
    print_colored "$CYAN" "📁 Report Locations:"
    print_colored "$CYAN" "  • XML Reports: $REPORTS_DIR/"
    print_colored "$CYAN" "  • Coverage Reports: $COVERAGE_DIR/"
}

# Function to cleanup
cleanup() {
    print_section "🧹 Cleanup"
    
    read -p "Do you want to stop infrastructure services? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$PROJECT_ROOT"
        docker-compose down --remove-orphans
        print_colored "$GREEN" "✅ Infrastructure services stopped"
    else
        print_colored "$CYAN" "📋 Infrastructure services left running"
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
🧪 Infrastructure Professional Testing Suite

Usage: $0 [OPTIONS] [COMMAND]

COMMANDS:
    setup           Setup infrastructure and dependencies only
    unit            Run unit tests only
    databases       Run database functionality tests
    web-services    Run web services tests
    messaging       Run RabbitMQ messaging tests  
    monitoring      Run monitoring and metrics tests
    comprehensive   Run complete test suite
    quick           Run quick smoke tests
    load            Run performance and load tests
    all             Run all test categories (default)
    
OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -k, --keep      Keep infrastructure running after tests
    --no-setup      Skip infrastructure setup
    --parallel      Run tests in parallel where possible
    --timeout=N     Set test timeout (default: $DEFAULT_TIMEOUT seconds)

EXAMPLES:
    $0                      # Run all tests with setup
    $0 databases           # Run only database tests
    $0 comprehensive       # Run comprehensive integration tests
    $0 --no-setup quick    # Quick test without infrastructure restart
    
EOF
}

# Main execution function
main() {
    local command="all"
    local skip_setup=false
    local keep_running=false
    local verbose=false
    local use_parallel=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -k|--keep)
                keep_running=true
                shift
                ;;
            --no-setup)
                skip_setup=true
                shift
                ;;
            --parallel)
                use_parallel=true
                shift
                ;;
            --timeout=*)
                DEFAULT_TIMEOUT="${1#*=}"
                shift
                ;;
            setup|unit|databases|web-services|messaging|monitoring|comprehensive|quick|load|all)
                command=$1
                shift
                ;;
            *)
                print_colored "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set verbose mode
    if [ "$verbose" = true ]; then
        set -x
    fi
    
    print_colored "$PURPLE" "🧪 Infrastructure Professional Testing Suite"
    print_colored "$PURPLE" "=============================================="
    
    local start_time=$(date +%s)
    local exit_code=0
    
    # Setup phase
    if [ "$skip_setup" = false ]; then
        check_dependencies
        setup_infrastructure
    else
        print_colored "$YELLOW" "⚠️  Skipping infrastructure setup"
    fi
    
    setup_reports
    
    # Test execution phase
    case $command in
        setup)
            print_colored "$GREEN" "✅ Setup complete"
            ;;
        unit)
            run_test_category "unit" "🔧 Unit Tests" "unit" 60 || exit_code=$?
            ;;
        databases)
            run_test_category "databases" "🗃️ Database Functionality Tests" "databases" 180 || exit_code=$?
            ;;
        web-services)
            run_test_category "web_services" "🌐 Web Services Tests" "web_services" 120 || exit_code=$?
            ;;
        messaging)
            run_test_category "messaging" "📨 Messaging Tests" "messaging" 120 || exit_code=$?
            ;;
        monitoring)
            run_test_category "monitoring" "📊 Monitoring Tests" "monitoring" 150 || exit_code=$?
            ;;
        comprehensive)
            run_test_category "comprehensive" "🎯 Comprehensive Integration Tests" "comprehensive" 600 || exit_code=$?
            ;;
        quick)
            run_test_category "quick" "⚡ Quick Smoke Tests" "integration and not comprehensive" 90 || exit_code=$?
            ;;
        load)
            run_test_category "load" "⚡ Performance and Load Tests" "performance" 300 || exit_code=$?
            ;;
        all)
            print_colored "$CYAN" "🎯 Running all test categories..."
            
            run_test_category "unit" "🔧 Unit Tests" "unit" 60 || exit_code=$?
            
            if [ $exit_code -eq 0 ]; then
                run_test_category "databases" "🗃️ Database Tests" "databases" 180 || exit_code=$?
            fi
            
            if [ $exit_code -eq 0 ]; then
                run_test_category "web_services" "🌐 Web Services Tests" "web_services" 120 || exit_code=$?
            fi
            
            if [ $exit_code -eq 0 ]; then
                run_test_category "messaging" "📨 Messaging Tests" "messaging" 120 || exit_code=$?
            fi
            
            if [ $exit_code -eq 0 ]; then
                run_test_category "monitoring" "📊 Monitoring Tests" "monitoring" 150 || exit_code=$?
            fi
            
            if [ $exit_code -eq 0 ]; then
                run_test_category "comprehensive" "🎯 Final Integration Tests" "comprehensive" 600 || exit_code=$?
            fi
            ;;
    esac
    
    # Generate summary
    generate_summary
    
    # Calculate execution time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_formatted=$(date -d@$duration -u +%H:%M:%S)
    
    print_section "🏁 Test Execution Complete"
    print_colored "$BLUE" "⏱️  Total execution time: $duration_formatted"
    
    if [ $exit_code -eq 0 ]; then
        print_colored "$GREEN" "🎉 All tests completed successfully!"
    else
        print_colored "$RED" "💥 Some tests failed (exit code: $exit_code)"
    fi
    
    # Cleanup
    if [ "$keep_running" = false ]; then
        cleanup
    else
        print_colored "$CYAN" "📋 Infrastructure services left running as requested"
    fi
    
    exit $exit_code
}

# Execute main function with all arguments
main "$@"