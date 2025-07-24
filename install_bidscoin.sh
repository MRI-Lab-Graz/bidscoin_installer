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
    echo "  $0                # Run BIDScoins installation"
    echo "  $0 --download     # Download latest script from GitHub"
    echo "  $0 --help        # Show this help message"
    echo ""
    echo "What this script does:"
    echo "  1. Clones BIDScoins repository from GitHub"
    echo "  2. Creates Python virtual environment"
    echo "  3. Installs UV package manager (fast Python installer)"
    echo "  4. Installs all BIDScoins dependencies"
    echo "  5. Installs BIDScoins in editable mode"
    echo "  6. Verifies the installation works"
    echo ""
    echo "Requirements:"
    echo "  - Python 3.8+"
    echo "  - Git"
    echo "  - Internet connection"
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

print_status "🧠 BIDScoins Automated Installation Starting..."
echo "======================================================"

# Check if this script was downloaded and needs to download itself
if [ "$1" = "--download" ]; then
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

# 1. Check for Python
print_status "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not found."
    exit 1
fi
print_success "Python 3 found"

# 2. Check for Git
print_status "Checking Git installation..."
if ! command -v git &> /dev/null; then
    print_error "Git is required but not found."
    exit 1
fi
print_success "Git found"

# 3. Clone BIDScoins repository
print_status "Cloning BIDScoins repository..."
INSTALL_DIR="bidscoin"

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory $INSTALL_DIR already exists. Removing it..."
    rm -rf "$INSTALL_DIR"
fi

git clone https://github.com/Donders-Institute/bidscoin.git "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    print_error "Failed to clone BIDScoins repository"
    exit 1
fi
print_success "Repository cloned successfully"

# 4. Change to the BIDScoins directory
cd "$INSTALL_DIR"
print_status "Entered BIDScoins directory: $(pwd)"

# 5. Create virtual environment
print_status "Creating Python virtual environment..."
ENV_NAME="bidscoin_env"

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
python -m pip install --upgrade pip
print_success "Pip upgraded"

# 8. Install UV package manager
print_status "Installing UV package manager..."
python -m pip install uv
print_success "UV package manager installed"

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

# 10. Install dependencies using UV
print_status "Installing BIDScoins dependencies with UV..."
uv pip install -e .
print_success "Dependencies and BIDScoins installed successfully"

# 11. Verify installation
print_status "Verifying BIDScoins installation..."
python -c "import bidscoin; print(f'BIDScoins version: {bidscoin.__version__}')"
print_success "BIDScoins installation verified"

# 12. Test basic functionality
print_status "Testing basic functionality..."
python -c "
try:
    import bidscoin
    from bidscoin import bids
    print('✓ Core modules imported successfully')
    print('✓ BIDScoins is ready to use')
except Exception as e:
    print(f'✗ Import test failed: {e}')
    exit(1)
"

echo ""
echo "======================================================"
print_success "🎉 BIDScoins installation completed successfully!"
echo "======================================================"
echo ""
print_status "Quick start:"
echo "1. Enter the BIDScoins directory: cd bidscoin"
echo "2. Activate the environment: source $ENV_NAME/bin/activate"
echo "3. Run BIDScoins commands or use Python: python -c 'import bidscoin'"
echo "4. Deactivate when done: deactivate"
echo ""
print_status "Installation directory: $(pwd)"
print_status "Virtual environment: $(pwd)/$ENV_NAME"
echo ""
print_status "Share this script with others:"
echo "• Download script: bash <(curl -s https://raw.githubusercontent.com/Donders-Institute/bidscoin/master/install_bidscoin.sh)"
echo "• Or get script file: curl -O https://raw.githubusercontent.com/Donders-Institute/bidscoin/master/install_bidscoin.sh"
echo ""
print_success "You're all set! Happy brain imaging! 🧠"
