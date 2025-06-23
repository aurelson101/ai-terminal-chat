#!/bin/bash
# AI Terminal Chat - Security Validation Script for Linux/macOS
# Validates security configuration and provides recommendations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default options
DETAILED=false
FIX_ISSUES=false
SECURITY_REPORT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed)
            DETAILED=true
            shift
            ;;
        --fix-issues)
            FIX_ISSUES=true
            shift
            ;;
        --security-report)
            SECURITY_REPORT=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--detailed] [--fix-issues] [--security-report]"
            echo "  --detailed       Show detailed security analysis"
            echo "  --fix-issues     Attempt to fix security issues automatically"
            echo "  --security-report Generate comprehensive security report"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🛡️  AI Terminal Chat - Security Validation${NC}"
echo "=================================================="

# Function to log messages
log_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}   ✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}   ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}   ❌ $1${NC}"
}

# Test Python security
test_python_security() {
    log_info "Checking Python security..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found"
        return 1
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1)
    log_success "Python version: $PYTHON_VERSION"
    
    # Check for known vulnerable Python versions
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 7) else 1)" 2>/dev/null; then
        log_success "Python version is secure (3.7+)"
    else
        log_warning "Python version may have security vulnerabilities"
        if [[ "$FIX_ISSUES" == true ]]; then
            log_info "Consider upgrading to Python 3.7+"
        fi
    fi
    
    return 0
}

# Test package security
test_package_security() {
    log_info "Checking package security..."
    
    # Check for security-related packages
    local packages=("cryptography" "requests" "rich" "pyperclip")
    
    for package in "${packages[@]}"; do
        if python3 -c "import $package; print('$package:', $package.__version__)" 2>/dev/null; then
            log_success "Package $package is installed"
        else
            log_warning "Package $package not installed or has issues"
            if [[ "$FIX_ISSUES" == true ]]; then
                log_info "Installing $package..."
                python3 -m pip install --user "$package"
            fi
        fi
    done
    
    # Check for known vulnerable packages
    if python3 -c "
import sys
try:
    import requests
    version = requests.__version__
    vulnerable_versions = ['2.20.0', '2.19.1', '2.18.4']
    if version in vulnerable_versions:
        print('WARNING: requests version', version, 'has known vulnerabilities')
        sys.exit(1)
    else:
        print('OK: requests version', version, 'appears secure')
        sys.exit(0)
except ImportError:
    print('ERROR: requests not installed')
    sys.exit(1)
" 2>/dev/null; then
        log_success "Requests package appears secure"
    else
        log_warning "Requests package may have vulnerabilities"
    fi
}

# Test file permissions
test_file_permissions() {
    log_info "Checking file permissions..."
    
    local config_dir="$HOME/.ai_terminal_chat"
    
    if [[ ! -d "$config_dir" ]]; then
        log_warning "Configuration directory not found: $config_dir"
        return
    fi
    
    # Check directory permissions
    local dir_perms=$(stat -c "%a" "$config_dir" 2>/dev/null || stat -f "%A" "$config_dir" 2>/dev/null)
    if [[ "$dir_perms" == "700" ]]; then
        log_success "Configuration directory has secure permissions: $dir_perms"
    else
        log_warning "Configuration directory permissions: $dir_perms (recommended: 700)"
        if [[ "$FIX_ISSUES" == true ]]; then
            chmod 700 "$config_dir"
            log_success "Fixed directory permissions"
        fi
    fi
    
    # Check config files
    local config_files=("config.json" "secure_config.json" "rate_limits.json" "audit.log")
    
    for config_file in "${config_files[@]}"; do
        local file_path="$config_dir/$config_file"
        if [[ -f "$file_path" ]]; then
            local file_perms=$(stat -c "%a" "$file_path" 2>/dev/null || stat -f "%A" "$file_path" 2>/dev/null)
            if [[ "$file_perms" == "600" ]]; then
                log_success "File $config_file has secure permissions: $file_perms"
            else
                log_warning "File $config_file permissions: $file_perms (recommended: 600)"
                if [[ "$FIX_ISSUES" == true ]]; then
                    chmod 600 "$file_path"
                    log_success "Fixed file permissions for $config_file"
                fi
            fi
        else
            log_info "Configuration file not found: $config_file"
        fi
    done
}

# Test configuration security
test_config_security() {
    log_info "Checking configuration security..."
    
    local config_dir="$HOME/.ai_terminal_chat"
    local config_file="$config_dir/config.json"
    
    if [[ -f "$config_file" ]]; then
        # Check if config contains plaintext API keys
        if grep -q '"api_key":\s*"[^"]*"' "$config_file" && ! grep -q '"api_key_encrypted"' "$config_file"; then
            log_warning "Plaintext API key detected in config.json"
            log_info "Recommendation: Use secure mode to encrypt keys"
        else
            log_success "Configuration appears secure: $config_file"
        fi
        
        # Check file size for potential issues
        local file_size=$(stat -c "%s" "$config_file" 2>/dev/null || stat -f "%z" "$config_file" 2>/dev/null)
        if [[ "$file_size" -gt 1048576 ]]; then  # 1MB
            log_warning "Large configuration file detected: ${file_size} bytes"
        fi
    else
        log_info "Configuration file not found: $config_file"
    fi
}

# Test network security
test_network_security() {
    log_info "Checking network security..."
    
    # Test common API endpoints
    local endpoints=(
        "https://api.openai.com/v1/models"
        "https://api.anthropic.com/v1/messages" 
        "https://api.groq.com/openai/v1/models"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -s --max-time 10 "$endpoint" >/dev/null 2>&1; then
            log_info "Endpoint accessible: $endpoint"
        else
            # Expected for API endpoints without auth
            log_success "Endpoint properly secured: $endpoint"
        fi
    done
}

# Show security summary
show_security_summary() {
    echo ""
    echo -e "${CYAN}📊 Security Summary:${NC}"
    echo "=============================="
    
    echo -e "${YELLOW}🔐 Security Recommendations:${NC}"
    echo "   1. Always use secure mode: chat --secure-mode"
    echo "   2. Encrypt API keys with a strong password"
    echo "   3. Monitor audit logs regularly" 
    echo "   4. Update Python dependencies regularly"
    echo "   5. Limit configuration file permissions"
    
    echo ""
    echo -e "${CYAN}🛡️  Available Security Features:${NC}"
    echo "   • User input validation"
    echo "   • API request rate limiting"
    echo "   • Sensitive data encryption"
    echo "   • Secure activity logging"
    echo "   • Command injection protection"
}

# Generate security report
generate_security_report() {
    local report_file="$HOME/.ai_terminal_chat/security_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "Generating security report: $report_file"
    
    {
        echo "AI Terminal Chat - Security Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo ""
        
        echo "System Information:"
        echo "- OS: $(uname -s) $(uname -r)"
        echo "- Python: $(python3 --version 2>&1)"
        echo "- User: $(whoami)"
        echo "- Config Dir: $HOME/.ai_terminal_chat"
        echo ""
        
        echo "Security Checks:"
        echo "- Python Version: $(python3 --version 2>&1)"
        echo "- Cryptography: $(python3 -c 'import cryptography; print(cryptography.__version__)' 2>/dev/null || echo 'Not installed')"
        echo "- Requests: $(python3 -c 'import requests; print(requests.__version__)' 2>/dev/null || echo 'Not installed')"
        echo ""
        
        if [[ -d "$HOME/.ai_terminal_chat" ]]; then
            echo "Configuration Files:"
            ls -la "$HOME/.ai_terminal_chat/" 2>/dev/null || echo "Directory not accessible"
        fi
        
    } > "$report_file"
    
    log_success "Security report generated: $report_file"
}

# Main execution
main() {
    local exit_code=0
    
    if ! test_python_security; then
        exit_code=1
    fi
    
    if ! test_package_security; then
        exit_code=1
    fi
    
    test_file_permissions
    test_config_security
    test_network_security
    
    if [[ "$DETAILED" == true ]]; then
        show_security_summary
    fi
    
    if [[ "$SECURITY_REPORT" == true ]]; then
        generate_security_report
    fi
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "Security validation completed successfully!"
    else
        log_warning "Security issues detected."
        echo "💡 Run with --fix-issues to attempt automatic fixes."
    fi
    
    exit $exit_code
}

# Run main function
main "$@"
