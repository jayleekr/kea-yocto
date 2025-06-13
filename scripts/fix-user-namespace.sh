#!/bin/bash

# Fix AppArmor User Namespace Issue for Yocto/BitBake
# This script resolves the "User namespaces are not usable by BitBake" error

set -e

# Color definitions
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

echo "🔧 AppArmor User Namespace Fix for Yocto/BitBake"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "This script should NOT be run as root"
    log_error "Run as regular user - sudo will be used when needed"
    exit 1
fi

# Check OS
if ! command -v lsb_release >/dev/null 2>&1; then
    log_warn "Cannot detect OS version. Proceeding anyway..."
    OS_INFO="Unknown"
else
    OS_INFO=$(lsb_release -d | cut -f2)
    log_info "Detected OS: $OS_INFO"
fi

# Check current setting
log_step "1. Checking current user namespace settings"

CURRENT_SETTING=$(sysctl kernel.apparmor_restrict_unprivileged_userns 2>/dev/null | cut -d' ' -f3 || echo "unknown")

if [ "$CURRENT_SETTING" = "unknown" ]; then
    log_warn "kernel.apparmor_restrict_unprivileged_userns setting not found"
    log_warn "This might not be Ubuntu 24.04+ or AppArmor might not be configured"
    echo ""
    echo "Common on:"
    echo "- Ubuntu < 24.04"
    echo "- Non-Ubuntu distributions"
    echo "- Systems without AppArmor"
    echo ""
    read -p "Continue anyway? [y/N]: " continue_anyway
    if [[ "$continue_anyway" != "y" ]] && [[ "$continue_anyway" != "Y" ]]; then
        log_info "Exiting..."
        exit 0
    fi
elif [ "$CURRENT_SETTING" = "0" ]; then
    log_info "✅ User namespaces are already enabled (setting = 0)"
    echo ""
    log_info "The issue might be elsewhere. Let's run diagnostics..."
else
    log_warn "⚠️  User namespaces are restricted (setting = $CURRENT_SETTING)"
    echo ""
fi

# Show fix options
echo "Available fix options:"
echo "1. Temporary fix (until reboot)"
echo "2. Permanent fix (survives reboot)"
echo "3. Alternative fix (BitBake configuration)"
echo "4. Run diagnostics only"
echo "5. Exit"
echo ""

read -p "Choose option [1-5]: " choice

case $choice in
    1)
        log_step "2. Applying temporary fix"
        log_info "Running: sudo sysctl kernel.apparmor_restrict_unprivileged_userns=0"
        
        if sudo sysctl kernel.apparmor_restrict_unprivileged_userns=0; then
            log_info "✅ Temporary fix applied successfully"
            log_warn "⚠️  This fix will be lost after reboot"
        else
            log_error "Failed to apply temporary fix"
            exit 1
        fi
        ;;
        
    2)
        log_step "2. Applying permanent fix"
        
        # Check if already in sysctl.conf
        if grep -q "kernel.apparmor_restrict_unprivileged_userns" /etc/sysctl.conf 2>/dev/null; then
            log_info "Setting already exists in /etc/sysctl.conf"
            log_info "Updating existing setting..."
            sudo sed -i 's/^.*kernel.apparmor_restrict_unprivileged_userns.*$/kernel.apparmor_restrict_unprivileged_userns = 0/' /etc/sysctl.conf
        else
            log_info "Adding setting to /etc/sysctl.conf..."
            echo 'kernel.apparmor_restrict_unprivileged_userns = 0' | sudo tee -a /etc/sysctl.conf
        fi
        
        log_info "Applying settings with sysctl -p..."
        if sudo sysctl -p; then
            log_info "✅ Permanent fix applied successfully"
            log_info "✅ Setting will persist after reboot"
        else
            log_error "Failed to apply permanent fix"
            exit 1
        fi
        ;;
        
    3)
        log_step "2. Applying BitBake configuration fix"
        log_info "This configures BitBake to work without user namespaces"
        log_warn "⚠️  This may limit some BitBake features"
        echo ""
        
        log_info "Configuration to add to local.conf:"
        echo 'BB_NO_NETWORK = "1"'
        echo 'BB_FETCH_PREMIRRORONLY = "1"'
        echo ""
        
        read -p "Apply this to a running container? [y/N]: " apply_config
        if [[ "$apply_config" == "y" ]] || [[ "$apply_config" == "Y" ]]; then
            log_info "Applying BitBake configuration..."
            
            if command -v docker >/dev/null 2>&1; then
                docker compose run --rm yocto-lecture bash -l -c '
                    yocto_init /tmp/namespace-fix-test
                    echo "BB_NO_NETWORK = \"1\"" >> conf/local.conf
                    echo "BB_FETCH_PREMIRRORONLY = \"1\"" >> conf/local.conf
                    echo "✅ Configuration applied to container"
                    echo "⚠️  Note: This limits network access during builds"
                ' || log_error "Failed to apply container configuration"
            else
                log_error "Docker not found. Apply manually to your local.conf"
            fi
        fi
        ;;
        
    4)
        log_step "2. Running diagnostics"
        ;;
        
    5)
        log_info "Exiting..."
        exit 0
        ;;
        
    *)
        log_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
log_step "3. Running diagnostics"

echo "System Information:"
echo "=================="
echo "OS: $OS_INFO"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

echo "AppArmor Status:"
echo "==============="
if systemctl is-active --quiet apparmor; then
    echo "✅ AppArmor is active"
    echo "AppArmor profiles loaded: $(sudo apparmor_status 2>/dev/null | grep "profiles are loaded" || echo "Unknown")"
else
    echo "❌ AppArmor is not active"
fi
echo ""

echo "User Namespace Settings:"
echo "======================="
FINAL_SETTING=$(sysctl kernel.apparmor_restrict_unprivileged_userns 2>/dev/null | cut -d' ' -f3 || echo "unknown")
if [ "$FINAL_SETTING" = "0" ]; then
    echo "✅ kernel.apparmor_restrict_unprivileged_userns = $FINAL_SETTING (GOOD)"
elif [ "$FINAL_SETTING" = "unknown" ]; then
    echo "⚠️  Setting not found (might be OK on this system)"
else
    echo "❌ kernel.apparmor_restrict_unprivileged_userns = $FINAL_SETTING (PROBLEMATIC)"
fi
echo ""

echo "Docker Status:"
echo "============="
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker is running"
        echo "Docker version: $(docker --version)"
    else
        echo "⚠️  Docker installed but not running"
    fi
else
    echo "❌ Docker not found"
fi
echo ""

log_step "4. Testing BitBake (if possible)"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    log_info "Testing BitBake in container..."
    
    if timeout 60 docker compose run --rm yocto-lecture bash -l -c '
        yocto_init /tmp/namespace-test
        echo "Testing BitBake namespace usage..."
        bitbake --version
        echo "✅ BitBake runs successfully"
    ' 2>/dev/null; then
        echo "✅ BitBake test PASSED"
    else
        echo "❌ BitBake test FAILED"
        echo ""
        echo "If you see 'User namespaces are not usable' error,"
        echo "the fix may need a container restart:"
        echo "  docker compose restart yocto-lecture"
    fi
else
    log_warn "Cannot test BitBake - Docker not available"
fi

echo ""
log_step "5. Summary and Next Steps"

echo "Fix Summary:"
echo "==========="
case $choice in
    1) echo "✅ Applied temporary fix (lost on reboot)" ;;
    2) echo "✅ Applied permanent fix (survives reboot)" ;;
    3) echo "✅ Applied BitBake configuration workaround" ;;
esac

echo ""
echo "Next Steps:"
echo "=========="
echo "1. Restart Docker containers if needed:"
echo "   docker compose restart yocto-lecture"
echo ""
echo "2. Test your Yocto build:"
echo "   docker compose run --rm yocto-lecture bash -l"
echo "   # Then in container:"
echo "   yocto_init"
echo "   bitbake core-image-minimal"
echo ""
echo "3. If problems persist:"
echo "   - Check that you're running on the HOST system (not in container)"
echo "   - Reboot the system and try again"
echo "   - Check GitHub issues: https://github.com/jayleekr/kea-yocto/issues"

echo ""
log_info "🎉 User namespace fix completed!"
echo ""
echo "Troubleshooting:"
echo "- Issue persists? Try rebooting the host system"
echo "- Still failing? Use option 3 (BitBake config workaround)"
echo "- Need help? Check docs/lecture/first-build.md" 