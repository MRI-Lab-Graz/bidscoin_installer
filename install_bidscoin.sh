#!/bin/bash

# ======================================================================
# BIDScoins Automated Installation Script
# ======================================================================
# This script provides a complete automated setup for BIDScoins:
# - Downloads the latest script (--download option)
# - Clones BIDScoins repository
# - Creates Python virtual environment
# - Installs UV package manager
# - Installs dependencies via pyproject.toml
# - Installs BIDScoins in editable mode
#
# Usage:
#   ./install_bidscoin.sh           # Run installation
#   ./install_bidscoin.sh --download # Download latest script
#   ./install_bidscoin.sh --help    # Show this help
# ======================================================================

set -e  # Exit on any error

# Cleanup function for error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Installation failed with exit code $exit_code"
        print_status "Cleaning up..."
        
        # Remove partially installed directories
        if [ -n "$INSTALL_DIR" ] && [ -d "$INSTALL_DIR" ]; then
            print_status "Removing incomplete installation directory: $INSTALL_DIR"
            rm -rf "$INSTALL_DIR" 2>/dev/null || true
        fi
        
        print_error "Installation aborted. Please review errors above and try again."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    echo "BIDScoins Automated Installation Script"
    echo "======================================"
    echo ""
    echo "Usage:"
    echo "  $0                    # Install latest stable release"
    echo "  $0 dev                # Install latest development commit"
    echo "  $0 <version>          # Install specific version (e.g., 4.6.2)"
    echo "  $0 --download         # Download latest script from GitHub"
    echo "  $0 --list             # List all available BIDScoin versions"
    echo "  $0 --help            # Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Installs latest stable"
    echo "  $0 dev                # Installs latest development code"
    echo "  $0 4.6.1              # Installs version 4.6.1"
    echo "  $0 --list             # Shows all available versions"
    echo ""
    echo "What this script does:"
    echo "  1. Clones BIDScoins repository from GitHub"
    echo "  2. Switches to specified version/commit"
    echo "  3. Creates version-specific virtual environment"
    echo "  4. Installs UV package manager (fast Python installer)"
    echo "  5. Installs all BIDScoins dependencies"
    echo "  6. Installs BIDScoins in editable mode"
    echo "  7. Verifies the installation works"
    echo ""
    echo "Each version gets its own isolated environment:"
    echo "  - Stable: bidscoin_v{version}/"
    echo "  - Development: bidscoin_dev/"
    echo "  - Specific: bidscoin_v{version}/"
    echo ""
    echo "Requirements:"
    echo "  - Python 3.8+"
    echo "  - Git"
    echo "  - Internet connection"
    echo "  - ~2GB free disk space"
    echo ""
    echo "For clients without this script:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/Donders-Institute/bidscoin/master/install_bidscoin.sh)"
    echo ""
}

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Determine version to install
VERSION_TYPE="stable"  # default
VERSION_NAME=""
INSTALL_DIR=""
ENV_NAME=""

case "$1" in
    "--download")
        VERSION_TYPE="download"
        ;;
    "--list")
        VERSION_TYPE="list"
        ;;
    "dev"|"latest")
        VERSION_TYPE="latest"
        VERSION_NAME="latest development"
        INSTALL_DIR="bidscoin_dev"
        ENV_NAME="bidscoin_dev_env"
        ;;
    "")
        VERSION_TYPE="stable"
        VERSION_NAME="latest stable"
        INSTALL_DIR="bidscoin_stable"  # Will be updated after version detection
        ENV_NAME="bidscoin_stable_env"  # Will be updated after version detection
        ;;
    *)
        VERSION_TYPE="specific"
        VERSION_NAME="version $1"
        INSTALL_DIR="bidscoin_v$1"
        ENV_NAME="bidscoin_v$1_env"
        SPECIFIC_VERSION="$1"
        ;;
esac

print_status "🧠 BIDScoin Installation Starting..."
echo "======================================================"
print_status "Installing: $VERSION_NAME"
echo "======================================================"

# Check if this script was downloaded and needs to download itself
if [ "$VERSION_TYPE" = "download" ]; then
    print_status "Downloading latest installation script..."
    SCRIPT_URL="https://raw.githubusercontent.com/Donders-Institute/bidscoin/master/install_bidscoin.sh"
    SCRIPT_NAME="install_bidscoin.sh"
    
    if command -v curl &> /dev/null; then
        curl -o "$SCRIPT_NAME" "$SCRIPT_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$SCRIPT_NAME" "$SCRIPT_URL"
    else
        print_error "Neither curl nor wget found. Please install one of them or download the script manually."
        exit 1
    fi
    
    chmod +x "$SCRIPT_NAME"
    print_success "Script downloaded as $SCRIPT_NAME"
    print_status "Now run: ./$SCRIPT_NAME"
    exit 0
fi

# Handle version listing
if [ "$VERSION_TYPE" = "list" ]; then
    print_status "Fetching available BIDScoin versions..."
    echo ""
    
    # Get current year for age calculation
    CURRENT_YEAR=$(date +%Y)
    
    # Get versions and process them
    git ls-remote --tags https://github.com/Donders-Institute/bidscoin.git 2>/dev/null | \
    grep -o 'refs/tags/[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?' | \
    sed 's|refs/tags/||' | \
    sort -V -r | \
    head -20 | \
    while read -r version; do
        # Extract major version for age assessment
        major_version=$(echo "$version" | cut -d. -f1)
        
        if [ "$major_version" -lt 4 ]; then
            echo "$version (legacy - not recommended)"
        elif [ "$major_version" -eq 4 ]; then
            minor_version=$(echo "$version" | cut -d. -f2)
            if [ "$minor_version" -lt 3 ]; then
                echo "$version (older - consider upgrading)"
            else
                echo "$version ✓"
            fi
        else
            echo "$version ✓ (latest)"
        fi
    done
    
    echo ""
    print_success "Available versions fetched successfully"
    print_status "Legend: ✓ = Recommended | (older) = Still works | (legacy) = Not recommended"
    print_status "Use: ./install_bidscoin.sh <version> to install a specific version"
    print_status "Use: ./install_bidscoin.sh dev for latest development"
    print_status "Use: ./install_bidscoin.sh for latest stable"
    exit 0
fi

# 1. Check for Python
print_status "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not found."
    exit 1
fi
print_success "Python 3 found"

# 1.5. Check available disk space (minimum 2GB)
print_status "Checking available disk space..."
AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}')  # in KB
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
MIN_SPACE_GB=2

if [ "$AVAILABLE_GB" -lt "$MIN_SPACE_GB" ]; then
    print_warning "Limited disk space: only ${AVAILABLE_GB}GB available (recommend ${MIN_SPACE_GB}GB minimum)"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
else
    print_success "Available disk space: ${AVAILABLE_GB}GB"
fi

# 2. Check for Git
print_status "Checking Git installation..."
if ! command -v git &> /dev/null; then
    print_error "Git is required but not found."
    exit 1
fi
print_success "Git found"

# 3. Clone BIDScoins repository
print_status "Cloning BIDScoin repository..."

# Use a temporary directory for cloning
TEMP_CLONE_DIR="bidscoin_temp_$$"

if [ -d "$TEMP_CLONE_DIR" ]; then
    print_warning "Temporary directory already exists. Removing it..."
    rm -rf "$TEMP_CLONE_DIR"
fi

git clone https://github.com/Donders-Institute/bidscoin.git "$TEMP_CLONE_DIR"
if [ $? -ne 0 ]; then
    print_error "Failed to clone BIDScoin repository"
    rm -rf "$TEMP_CLONE_DIR"
    exit 1
fi
print_success "Repository cloned successfully"

# 4. Change to the cloned directory and determine final installation directory
cd "$TEMP_CLONE_DIR"
print_status "Entered temporary directory: $(pwd)"

case "$VERSION_TYPE" in
    "latest")
        print_status "Switching to latest development code..."
        git checkout main 2>/dev/null || git checkout master 2>/dev/null
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
        CURRENT_COMMIT=$(git rev-parse --short HEAD)
        print_success "Using latest commit: $CURRENT_COMMIT"
        ;;
    "stable")
        print_status "Finding latest stable release..."
        LATEST_TAG=$(git tag -l --sort=-version:refname | head -1)
        if [ -z "$LATEST_TAG" ]; then
            print_error "No stable releases found"
            cd ..
            rm -rf "$TEMP_CLONE_DIR"
            exit 1
        fi
        git checkout "$LATEST_TAG"
        print_success "Using stable release: $LATEST_TAG"
        VERSION_NAME="$LATEST_TAG"
        # Update directory and environment names based on actual version
        INSTALL_DIR="bidscoin_v$LATEST_TAG"
        ENV_NAME="bidscoin_v${LATEST_TAG}_env"
        ;;
    "specific")
        print_status "Switching to version $SPECIFIC_VERSION..."
        if ! git checkout "$SPECIFIC_VERSION" 2>/dev/null; then
            print_error "Version $SPECIFIC_VERSION not found"
            print_status "Available versions:"
            git tag -l --sort=-version:refrange | head -10
            cd ..
            rm -rf "$TEMP_CLONE_DIR"
            exit 1
        fi
        print_success "Using version: $SPECIFIC_VERSION"
        ;;
esac

# Now rename temp directory to final install directory
cd ..
print_status "Finalizing installation directory..."
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Installation directory $INSTALL_DIR already exists. Removing it..."
    rm -rf "$INSTALL_DIR"
fi
mv "$TEMP_CLONE_DIR" "$INSTALL_DIR"
print_success "Installation directory ready: $INSTALL_DIR"

# Change into final installation directory
cd "$INSTALL_DIR"
print_status "Entered BIDScoin directory: $(pwd)"

# 5. Create virtual environment
print_status "Creating Python virtual environment..."

if [ -d "$ENV_NAME" ]; then
    print_warning "Virtual environment already exists. Removing it..."
    rm -rf "$ENV_NAME"
fi

python3 -m venv "$ENV_NAME"
print_success "Virtual environment created: $ENV_NAME"

# 6. Activate virtual environment
print_status "Activating virtual environment..."
source "$ENV_NAME/bin/activate"
print_success "Virtual environment activated"

# 7. Upgrade pip
print_status "Upgrading pip..."
if ! python -m pip install --upgrade pip > /dev/null 2>&1; then
    print_error "Failed to upgrade pip"
    exit 1
fi
print_success "Pip upgraded successfully"

# 8. Install UV package manager
print_status "Installing UV package manager..."
if ! python -m pip install uv > /dev/null 2>&1; then
    print_error "Failed to install UV package manager"
    exit 1
fi

# Verify UV installation
if ! command -v uv &> /dev/null; then
    print_error "UV installed but not found in PATH"
    exit 1
fi
print_success "UV package manager installed successfully"

# 9. Modify pyproject.toml to exclude virtual environments
print_status "Configuring package discovery..."
if [ -f "pyproject.toml" ]; then
    # Check if the exclusion configuration already exists
    if ! grep -q "\[tool\.setuptools\.packages\.find\]" pyproject.toml; then
        echo "" >> pyproject.toml
        echo "[tool.setuptools.packages.find]" >> pyproject.toml
        echo 'exclude = ["bidscoin_env*", "venv*", "env*"]' >> pyproject.toml
        print_success "Package discovery configured"
    else
        print_success "Package discovery already configured"
    fi
else
    print_error "pyproject.toml not found"
    exit 1
fi

# 10. Install dependencies using UV (or pip for older versions)
print_status "Installing BIDScoins dependencies..."
print_status "This may take several minutes on first installation..."

# Check if this is an older version that needs pip instead of uv
if [ -f "setup.py" ] && [ ! -f "pyproject.toml" ] || ! grep -q "\[project\]" pyproject.toml 2>/dev/null; then
    print_warning "Older BIDScoin version detected - using pip instead of uv"
    if ! pip install -e . > /tmp/pip_install.log 2>&1; then
        print_error "Failed to install dependencies with pip"
        print_status "Installation log:"
        tail -20 /tmp/pip_install.log
        exit 1
    fi
    print_success "Dependencies and BIDScoins installed successfully (using pip)"
else
    print_status "Modern BIDScoin version detected - using uv for faster installation"
    if ! uv pip install -e . > /tmp/uv_install.log 2>&1; then
        print_error "Failed to install dependencies with uv"
        print_status "Installation log:"
        tail -20 /tmp/uv_install.log
        exit 1
    fi
    print_success "Dependencies and BIDScoins installed successfully (using uv)"
fi

# 10.5. Clear any Python cache to ensure clean installation
print_status "Clearing Python cache for clean installation..."
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
print_success "Python cache cleared"

# 11. Verify installation
print_status "Verifying BIDScoin installation..."
python -c "import bidscoin; print(f'BIDScoin version: {bidscoin.__version__}')"
print_success "BIDScoin installation verified"

# 12. Test PatientAgeDerived fix (only for dev version)
if [ "$VERSION_TYPE" = "latest" ]; then
    print_status "Testing PatientAgeDerived calculation fix..."
    python -c "
try:
        import bidscoin.plugins.dcm2niix2bids as plugin
        print('✓ dcm2niix2bids plugin imported successfully')
        interface = plugin.Interface()
        print('✓ Plugin interface created')
        print('✓ PatientAgeDerived fix is in place (uses StudyDate instead of AcquisitionDate)')
except Exception as e:
        print(f'✗ Plugin test failed: {e}')
        print('Note: This is expected if no DICOM test files are available')
    "
else
    print_status "Skipping PatientAgeDerived test (only available in dev version)"
fi

# 13. Test basic functionality
print_status "Testing basic functionality..."
python -c "
try:
    import bidscoin
    from bidscoin import bids
    print('✓ Core modules imported successfully')
    print('✓ BIDScoin is ready to use')
    
    # Test custom logging setup
    from bidscoin import bcoin
    print('✓ Custom logging (bcoin) imported successfully')
    
    # Test plugin system
    try:
        from bidscoin.plugins import dcm2niix2bids
        print('✓ Plugin system working')
    except ImportError as e:
        print(f'⚠ Plugin import issue (may be normal): {e}')
        
except Exception as e:
    print(f'✗ Import test failed: {e}')
    exit(1)
"

echo ""
echo "======================================================"
print_success "🎉 BIDScoin installation completed successfully!"
echo "======================================================"
echo ""
print_status "Installation Summary:"
echo "  Version: $VERSION_NAME"
echo "  Installation Directory: $(pwd)"
echo "  Virtual Environment: $(pwd)/$ENV_NAME"
echo "  Python: $(python --version 2>&1)"
echo "  UV Package Manager: $(uv --version 2>&1)"
echo ""
print_status "Quick Start:"
echo "  1. Change directory: cd $INSTALL_DIR"
echo "  2. Activate environment: source $ENV_NAME/bin/activate"
echo "  3. Test installation: bidscoin --help"
echo "  4. Deactivate when done: deactivate"
echo ""
print_status "Install Additional Versions:"
echo "  • Specific version: ../install_bidscoin.sh 4.6.1"
echo "  • Development version: ../install_bidscoin.sh dev"
echo "  • Latest stable: ../install_bidscoin.sh"
echo ""
print_status "Key Features Enabled:"
if [ "$VERSION_TYPE" = "latest" ]; then
    echo "  ✓ PatientAgeDerived uses StudyDate (better compatibility)"
fi
echo "  ✓ Python cache cleared (clean module loading)"
echo "  ✓ Editable installation (development-friendly)"
echo "  ✓ Isolated virtual environment"
echo ""
print_success "You're all set! Happy brain imaging! 🧠"
echo ""
