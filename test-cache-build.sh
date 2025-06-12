#!/bin/bash

# KEA Yocto Cache Download and Build Test Runner
# This script runs comprehensive tests as described in README.md
# Cross-platform compatible (Linux, macOS)

set -euo pipefail

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
else
    IS_MACOS=false
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "🧪 KEA Yocto Cache Download and Build Test"
echo "=========================================="
echo ""

# Default parameters
WORKSPACE="./yocto-workspace-test" 
TARGET="core-image-minimal"
VERBOSE=""
SAVE_RESULTS=""

show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --workspace DIR       Test workspace directory (default: ./yocto-workspace-test)"
    echo "  --target TARGET       Build target (default: core-image-minimal)"
    echo "  --verbose            Enable verbose logging"
    echo "  --save-results FILE  Save results to specific JSON file"
    echo "  --help               Show this help"
    echo ""
    echo "This script performs comprehensive testing of:"
    echo "  ✅ Cache download from GitHub releases"
    echo "  ✅ Tarball integrity verification"
    echo "  ✅ Cache extraction and setup"
    echo "  ✅ Actual Yocto build with cached files"
    echo "  ✅ Performance analysis vs README.md claims"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run with defaults"
    echo "  $0 --verbose                        # Run with verbose output"
    echo "  $0 --workspace ./my-test --target core-image-base"
    echo "  $0 --save-results my-test-results.json"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE="--verbose"
            shift
            ;;
        --save-results)
            SAVE_RESULTS="--save-results $2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

log_step "Checking test environment..."

# Check if Python test script exists
if [ ! -f "scripts/test-cache-download-build.py" ]; then
    log_error "Test script not found: scripts/test-cache-download-build.py"
    exit 1
fi

# Check Python requirements (cross-platform)
if ! python3 -c "import requests" 2>/dev/null; then
    log_warn "Python 'requests' module not found, installing..."
    if $IS_MACOS; then
        # On macOS, try pip3 first, then python3 -m pip
        if command -v pip3 >/dev/null 2>&1; then
            pip3 install requests
        elif python3 -m pip --version >/dev/null 2>&1; then
            python3 -m pip install requests
        else
            log_error "Could not find pip3 or python3 -m pip. Please install requests manually:"
            log_error "  python3 -m pip install requests"
            exit 1
        fi
    else
        # Linux
        pip3 install requests
    fi
fi

log_step "Starting comprehensive cache test..."

# Build command
CMD="python3 scripts/test-cache-download-build.py"
CMD="$CMD --workspace $WORKSPACE"
CMD="$CMD --target $TARGET"
if [ -n "$VERBOSE" ]; then
    CMD="$CMD $VERBOSE"
fi
if [ -n "$SAVE_RESULTS" ]; then
    CMD="$CMD $SAVE_RESULTS"
fi

log_info "Running: $CMD"
echo ""

# Execute test
if eval "$CMD"; then
    echo ""
    log_info "🎉 All tests completed successfully!"
    log_info "Cache download and build system is working as described in README.md"
    
    # Show next steps
    echo ""
    echo "📋 Next Steps:"
    echo "  • Review the test report above"
    echo "  • Check workspace: $WORKSPACE"
    echo "  • Use cached builds as described in README.md"
    echo "  • Run './download-cache.sh' for production use"
    
    exit 0
else
    echo ""
    log_error "❌ Some tests failed!"
    log_error "Please check the error messages above"
    
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  • Check Docker is running: docker --version"
    if $IS_MACOS; then
        echo "  • macOS: Ensure Docker Desktop is running and configured"
        echo "  • macOS: Check Docker Desktop settings > Resources > File Sharing"
        echo "  • macOS: If using Homebrew: brew install gnu-tar (for gtar)"
    fi
    echo "  • Check internet connection"
    echo "  • Ensure sufficient disk space (>10GB)"
    echo "  • Run with --verbose for more details"
    if $IS_MACOS; then
        echo "  • macOS: Try 'python3 -m pip install requests' if pip3 fails"
    fi
    
    exit 1
fi 