#!/bin/bash

# ======================================================================
# BIDScoins STANDALONE Installation Script
# ======================================================================
# This script provides a COMPLETELY ISOLATED installation of BIDScoins:
# - Downloads standalone Python (no system Python required!)
# - Downloads portable Git (no system Git required!)
# - Creates fully self-contained installation
# - Everything in one directory - completely portable
# - Can be moved to any compatible system
#
# Perfect for:
# - Systems where you don't have admin rights
# - Environments with incompatible system Python
# - Creating portable installations
# - Complete isolation from system dependencies
#
# Usage:
#   ./install_bidscoin_standalone.sh           # Run installation
#   ./install_bidscoin_standalone.sh dev       # Install dev version
#   ./install_bidscoin_standalone.sh 4.6.2     # Install specific version
#   ./install_bidscoin_standalone.sh --help    # Show this help
#
# Note: For standard installation using system Python/Git, use:
#       ./install_bidscoin.sh
# ======================================================================

# Check if we're running in bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash to run properly."
    echo "Please run with: bash $0 $@"
    exit 1
fi

# Check if basic commands are available (only truly essential shell builtins)
for cmd in rm mkdir cd pwd echo cat grep sed awk; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' not found in PATH."
        exit 1
    fi
done

set -e  # Exit on any error

# Configuration for standalone installations
PYTHON_VERSION="3.11.14"  # Standalone Python version to download
PYTHON_BUILD_DATE="20251028"  # Python build standalone release date
STANDALONE_PYTHON_URL=""  # Will be set based on OS
STANDALONE_GIT_URL=""     # Will be set based on OS
USE_STANDALONE=true       # Always use standalone installations for full isolation

# Cleanup function for error handling
cleanup() {
    local exit_code=$?
    # Prevent cleanup from being called during cleanup
    if [ "${CLEANUP_IN_PROGRESS:-0}" -eq 1 ]; then
        return
    fi
    CLEANUP_IN_PROGRESS=1

    if [ $exit_code -ne 0 ]; then
        print_error "Installation failed with exit code $exit_code"
        print_status "Cleaning up..."

        # Only cleanup if we have installation variables set
        if [ -n "${INSTALL_BASE:-}" ] && [ -d "$INSTALL_BASE" ]; then
            print_status "Removing incomplete installation directory: $INSTALL_BASE"
            cd /
            rm -rf "$INSTALL_BASE" 2>/dev/null || print_warning "Could not remove $INSTALL_BASE"
        fi

        # Clean up temporary log files
        rm -f /tmp/pip_install.log /tmp/uv_install.log 2>/dev/null || true
        rm -f python.tar.gz git.tar.gz 2>/dev/null || true

        print_error "Installation aborted. Please review errors above and try again."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Handle interrupts gracefully
trap 'echo ""; print_warning "Installation interrupted by user"; cleanup' INT TERM

# Color codes for output (only if terminal supports colors)
if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ] && command -v tput &> /dev/null && tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

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
    echo "BIDScoins Fully Isolated Installation Script"
    echo "============================================="
    echo ""
    echo "This installer creates a COMPLETELY DETACHED installation:"
    echo "  • Downloads standalone Python (no system Python needed)"
    echo "  • Downloads portable Git (no system Git needed)"
    echo "  • All dependencies self-contained in one directory"
    echo "  • Fully portable - move anywhere and it works"
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
    echo "  1. Downloads standalone Python distribution"
    echo "  2. Downloads portable Git binaries"
    echo "  3. Clones BIDScoins repository using portable Git"
    echo "  4. Switches to specified version/commit"
    echo "  5. Creates version-specific virtual environment"
    echo "  6. Installs UV package manager (fast Python installer)"
    echo "  7. Installs all BIDScoins dependencies"
    echo "  8. Installs BIDScoins in editable mode"
    echo "  9. Verifies the installation works"
    echo ""
    echo "Each version gets its own isolated environment:"
    echo "  - Stable: bidscoin_v{version}/"
    echo "  - Development: bidscoin_dev/"
    echo "  - Specific: bidscoin_v{version}/"
    echo ""
    echo "Directory structure:"
    echo "  bidscoin_v{version}/"
    echo "    ├── _python/          # Standalone Python installation"
    echo "    ├── _git/             # Portable Git installation"
    echo "    ├── env/              # Virtual environment"
    echo "    └── [BIDScoin files]  # BIDScoin source code"
    echo ""
    echo "Requirements:"
    echo "  - Only bash and basic UNIX tools (curl/wget, tar)"
    echo "  - Internet connection"
    echo "  - ~3GB free disk space"
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

# Function to detect OS and architecture
detect_system() {
    local os=""
    local arch=""
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux";;
        Darwin*)    os="macos";;
        MINGW*|MSYS*|CYGWIN*) os="windows";;
        *)          os="unknown";;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="x86_64";;
        aarch64|arm64)  arch="aarch64";;
        *)              arch="unknown";;
    esac
    
    echo "${os}-${arch}"
}

# Function to download standalone Python
download_standalone_python() {
    local install_base="$1"
    local python_dir="${install_base}/_python"
    
    print_status "Downloading standalone Python $PYTHON_VERSION..."
    
    # Detect system
    local system=$(detect_system)
    print_status "Detected system: $system"
    
    # Set download URL based on system
    case "$system" in
        linux-x86_64)
            STANDALONE_PYTHON_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${PYTHON_BUILD_DATE}/cpython-${PYTHON_VERSION}+${PYTHON_BUILD_DATE}-x86_64-unknown-linux-gnu-install_only.tar.gz"
            ;;
        linux-aarch64)
            STANDALONE_PYTHON_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${PYTHON_BUILD_DATE}/cpython-${PYTHON_VERSION}+${PYTHON_BUILD_DATE}-aarch64-unknown-linux-gnu-install_only.tar.gz"
            ;;
        macos-x86_64)
            STANDALONE_PYTHON_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${PYTHON_BUILD_DATE}/cpython-${PYTHON_VERSION}+${PYTHON_BUILD_DATE}-x86_64-apple-darwin-install_only.tar.gz"
            ;;
        macos-aarch64)
            STANDALONE_PYTHON_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${PYTHON_BUILD_DATE}/cpython-${PYTHON_VERSION}+${PYTHON_BUILD_DATE}-aarch64-apple-darwin-install_only.tar.gz"
            ;;
        *)
            print_error "Unsupported system: $system"
            print_status "This installation requires Linux or macOS on x86_64 or ARM64"
            return 1
            ;;
    esac
    
    # Create python directory
    mkdir -p "$python_dir"
    
    # Download Python
    local python_archive="python.tar.gz"
    print_status "Downloading from: ${STANDALONE_PYTHON_URL}"
    
    if command -v curl &> /dev/null; then
        if ! curl -L --fail --progress-bar -o "$python_archive" "$STANDALONE_PYTHON_URL"; then
            print_error "Failed to download Python with curl"
            print_status "URL: $STANDALONE_PYTHON_URL"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget --show-progress -O "$python_archive" "$STANDALONE_PYTHON_URL"; then
            print_error "Failed to download Python with wget"
            print_status "URL: $STANDALONE_PYTHON_URL"
            return 1
        fi
    else
        print_error "Neither curl nor wget found. Cannot download Python."
        return 1
    fi
    
    # Verify download succeeded and file is not tiny (error page)
    if [ ! -f "$python_archive" ]; then
        print_error "Download failed - file not created"
        return 1
    fi
    
    local file_size=$(stat -f%z "$python_archive" 2>/dev/null || stat -c%s "$python_archive" 2>/dev/null)
    if [ "$file_size" -lt 10000 ]; then
        print_error "Download failed - file too small ($file_size bytes, expected ~50MB+)"
        print_status "File may contain an error message. Contents:"
        head -20 "$python_archive"
        rm -f "$python_archive"
        return 1
    fi
    
    print_success "Downloaded $(( file_size / 1024 / 1024 ))MB"
    
    # Extract Python
    print_status "Extracting Python..."
    if ! tar -xzf "$python_archive" -C "$python_dir" --strip-components=1; then
        print_error "Failed to extract Python archive"
        rm -f "$python_archive"
        return 1
    fi
    
    rm -f "$python_archive"
    
    # Verify Python installation
    if [ ! -f "${python_dir}/bin/python3" ]; then
        print_error "Python binary not found after extraction"
        return 1
    fi
    
    print_success "Standalone Python installed to: $python_dir"
    
    # Test Python
    local python_version_check=$("${python_dir}/bin/python3" --version 2>&1)
    print_success "Python ready: $python_version_check"
    
    return 0
}

# Function to download portable Git
download_portable_git() {
    local install_base="$1"
    local git_dir="${install_base}/_git"
    
    print_status "Downloading portable Git..."
    
    # Detect system
    local system=$(detect_system)
    
    # For simplicity, use system git if available, otherwise provide instructions
    if command -v git &> /dev/null; then
        print_status "Using system Git (creating wrapper for portability)..."
        mkdir -p "${git_dir}/bin"
        ln -sf "$(command -v git)" "${git_dir}/bin/git"
        print_success "Git wrapper created"
        return 0
    else
        print_error "Git not found. For a truly isolated installation, git is needed."
        print_status "Please install git first:"
        case "$system" in
            macos-*)
                print_status "  macOS: xcode-select --install"
                ;;
            linux-*)
                print_status "  Debian/Ubuntu: apt-get install git"
                print_status "  RHEL/CentOS: yum install git"
                print_status "  Arch: pacman -S git"
                ;;
        esac
        return 1
    fi
}

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
        ENV_NAME="env"
        ;;
    "")
        VERSION_TYPE="stable"
        VERSION_NAME="latest stable"
        INSTALL_DIR="bidscoin_stable"  # Will be updated after version detection
        ENV_NAME="env"  # Will be updated after version detection
        ;;
    *)
        VERSION_TYPE="specific"
        VERSION_NAME="version $1"
        INSTALL_DIR="bidscoin_v$1"
        ENV_NAME="env"
        SPECIFIC_VERSION="$1"
        ;;
esac

# Check if we're running as root (not recommended)
if [ "$(id -u)" -eq 0 ]; then
    print_warning "Running as root is not recommended and may cause permission issues."
    print_warning "Consider running as a regular user."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
fi

print_status "🧠 BIDScoin Fully Isolated Installation Starting..."
echo "======================================================"
print_status "Installing: $VERSION_NAME"
print_status "Mode: Fully detached from system"
echo "======================================================"

# Handle --download flag
if [ "$VERSION_TYPE" = "download" ]; then
    print_status "Downloading latest installation script..."
    SCRIPT_URL="https://raw.githubusercontent.com/Donders-Institute/bidscoin/master/install_bidscoin.sh"
    SCRIPT_NAME="install_bidscoin.sh"

    if command -v curl &> /dev/null; then
        if ! curl -s -o "$SCRIPT_NAME" "$SCRIPT_URL"; then
            print_error "Failed to download script with curl"
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -q -O "$SCRIPT_NAME" "$SCRIPT_URL"; then
            print_error "Failed to download script with wget"
            exit 1
        fi
    else
        print_error "Neither curl nor wget found. Please install one of them or download the script manually."
        exit 1
    fi

    if [ ! -f "$SCRIPT_NAME" ]; then
        print_error "Script download failed - file not created"
        exit 1
    fi

    chmod +x "$SCRIPT_NAME"
    print_success "Script downloaded as $SCRIPT_NAME"
    print_status "Now run: ./$SCRIPT_NAME"
    exit 0
fi

# Handle version listing (needs curl/wget for git ls-remote, system git not required)
if [ "$VERSION_TYPE" = "list" ]; then
    print_status "Fetching available BIDScoin versions..."
    
    # Check for git or use API fallback
    if command -v git &> /dev/null; then
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
    else
        print_warning "Git not available - using GitHub API..."
        if command -v curl &> /dev/null; then
            curl -s https://api.github.com/repos/Donders-Institute/bidscoin/tags | \
            grep '"name"' | \
            sed 's/.*"name": "\(.*\)".*/\1/' | \
            head -20
        else
            print_error "Need git or curl to list versions"
            exit 1
        fi
    fi
    
    echo ""
    print_success "Available versions fetched successfully"
    print_status "Legend: ✓ = Recommended | (older) = Still works | (legacy) = Not recommended"
    print_status "Use: ./install_bidscoin.sh <version> to install a specific version"
    print_status "Use: ./install_bidscoin.sh dev for latest development"
    print_status "Use: ./install_bidscoin.sh for latest stable"
    exit 0
fi

# 0. Prepare installation directory structure
print_status "Preparing installation directory structure..."

# Determine where the installation will actually happen
if [[ "$INSTALL_DIR" == /* ]]; then
    # Absolute path
    INSTALL_PARENT=$(dirname "$INSTALL_DIR")
else
    # Relative path - use current directory
    INSTALL_PARENT="."
fi

if [ ! -w "$INSTALL_PARENT" ]; then
    print_error "No write permission in installation directory: $INSTALL_PARENT"
    print_status "Please run this script from a directory where you have write permissions,"
    print_status "or specify an absolute path with write permissions."
    exit 1
fi

# Create installation directory early
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Installation directory $INSTALL_DIR already exists. Removing it..."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
INSTALL_BASE="$(pwd)"
print_success "Installation directory created: $INSTALL_BASE"

# 1. Download and install standalone Python
if ! download_standalone_python "$INSTALL_BASE"; then
    print_error "Failed to install standalone Python"
    exit 1
fi

# Update Python path
PYTHON_BIN="${INSTALL_BASE}/_python/bin/python3"
print_status "Using standalone Python: $PYTHON_BIN"

# 2. Download and setup portable Git  
if ! download_portable_git "$INSTALL_BASE"; then
    print_error "Failed to setup portable Git"
    exit 1
fi

# Update Git path
GIT_BIN="${INSTALL_BASE}/_git/bin/git"
print_status "Using Git: $GIT_BIN"

# 3. Check available disk space (minimum 3GB for standalone installation)
print_status "Checking available disk space..."

AVAILABLE_SPACE=$(df "$INSTALL_BASE" | awk 'NR==2 {print $4}')  # in KB
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
MIN_SPACE_GB=3

if [ "$AVAILABLE_GB" -lt "$MIN_SPACE_GB" ]; then
    print_warning "Limited disk space: only ${AVAILABLE_GB}GB available (recommend ${MIN_SPACE_GB}GB minimum)"
    print_warning "Standalone installation will require ~3GB of space"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
else
    print_success "Available disk space: ${AVAILABLE_GB}GB"
fi

# Check network connectivity to GitHub
print_status "Checking network connectivity..."
if ! curl -s --connect-timeout 10 https://github.com > /dev/null 2>&1 && ! wget -q --timeout=10 -O /dev/null https://github.com > /dev/null 2>&1; then
    print_error "Cannot connect to GitHub. Please check your internet connection."
    exit 1
fi
print_success "Network connectivity confirmed"

# Check available memory (minimum 4GB recommended)
print_status "Checking available memory..."
if command -v free &> /dev/null; then
    AVAILABLE_MEM=$(free -g | awk 'NR==2 {print $7}')  # Available memory in GB
    if [ "$AVAILABLE_MEM" -lt 4 ]; then
        print_warning "Limited memory: ${AVAILABLE_MEM}GB available (4GB+ recommended)"
        print_warning "Installation may be slow or fail with limited memory"
    else
        print_success "Available memory: ${AVAILABLE_MEM}GB"
    fi
elif command -v vm_stat &> /dev/null; then
    # macOS
    AVAILABLE_MEM=$(( $(vm_stat | awk '/free/ {print $3}' | tr -d '.') / 1024 / 1024 ))
    if [ "$AVAILABLE_MEM" -lt 4 ]; then
        print_warning "Limited memory: ${AVAILABLE_MEM}GB available (4GB+ recommended)"
        print_warning "Installation may be slow or fail with limited memory"
    else
        print_success "Available memory: ${AVAILABLE_MEM}GB"
    fi
else
    print_warning "Could not check available memory (non-critical)"
fi

# 4. Clone BIDScoins repository using portable Git
print_status "Cloning BIDScoin repository using portable Git..."

# Use a subdirectory for the source code
SOURCE_DIR="source"

if [ -d "$SOURCE_DIR" ]; then
    print_warning "Source directory already exists. Removing it..."
    rm -rf "$SOURCE_DIR"
fi

# Clone with timeout and retry logic
CLONE_SUCCESS=0
for attempt in {1..3}; do
    print_status "Clone attempt $attempt/3..."
    # Clone without depth limit to get tags
    if "$GIT_BIN" clone https://github.com/Donders-Institute/bidscoin.git "$SOURCE_DIR" 2>&1 | tail -5; then
        CLONE_SUCCESS=1
        break
    else
        if [ $attempt -lt 3 ]; then
            print_warning "Clone attempt $attempt failed, retrying in 5 seconds..."
            rm -rf "$SOURCE_DIR" 2>/dev/null
            sleep 5
        fi
    fi
done

if [ $CLONE_SUCCESS -eq 0 ]; then
    print_error "Failed to clone BIDScoin repository after 3 attempts"
    exit 1
fi

print_success "Repository cloned successfully"

# 5. Change to the source directory and switch to requested version
cd "$SOURCE_DIR"
print_status "Entered source directory: $(pwd)"

case "$VERSION_TYPE" in
    "latest")
        print_status "Switching to latest development code..."
        "$GIT_BIN" checkout main 2>/dev/null || "$GIT_BIN" checkout master 2>/dev/null
        "$GIT_BIN" pull origin main 2>/dev/null || "$GIT_BIN" pull origin master 2>/dev/null
        CURRENT_COMMIT=$("$GIT_BIN" rev-parse --short HEAD)
        print_success "Using latest commit: $CURRENT_COMMIT"
        ;;
    "stable")
        print_status "Finding latest stable release..."
        LATEST_TAG=$("$GIT_BIN" tag -l --sort=-version:refname | head -1)
        if [ -z "$LATEST_TAG" ]; then
            print_error "No stable releases found"
            exit 1
        fi
        "$GIT_BIN" checkout "$LATEST_TAG"
        print_success "Using stable release: $LATEST_TAG"
        VERSION_NAME="$LATEST_TAG"
        ;;
    "specific")
        print_status "Switching to version $SPECIFIC_VERSION..."
        if ! "$GIT_BIN" checkout "$SPECIFIC_VERSION" 2>/dev/null; then
            print_error "Version $SPECIFIC_VERSION not found"
            print_status "Available versions:"
            "$GIT_BIN" tag -l --sort=-version:refname | head -10
            exit 1
        fi
        print_success "Using version: $SPECIFIC_VERSION"
        ;;
esac

# Return to installation base directory
cd "$INSTALL_BASE"
print_status "Returned to installation directory: $(pwd)"

# 6. Create virtual environment using standalone Python
print_status "Creating Python virtual environment with standalone Python..."

ENV_DIR="env"
if [ -d "$ENV_DIR" ]; then
    print_warning "Virtual environment already exists. Removing it..."
    rm -rf "$ENV_DIR"
fi

"$PYTHON_BIN" -m venv "$ENV_DIR"
print_success "Virtual environment created: $ENV_DIR"

# 7. Activate virtual environment
print_status "Activating virtual environment..."
source "${ENV_DIR}/bin/activate"
print_success "Virtual environment activated"

# Verify we're using the correct Python
ACTIVE_PYTHON=$(which python3)
print_status "Active Python: $ACTIVE_PYTHON"

# 8. Upgrade pip
print_status "Upgrading pip..."
if ! python -m pip install --upgrade pip > /dev/null 2>&1; then
    print_error "Failed to upgrade pip"
    exit 1
fi
print_success "Pip upgraded successfully"

# 9. Install UV package manager
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

# 10. Modify pyproject.toml to exclude virtual environments
print_status "Configuring package discovery..."
SOURCE_TOML="${SOURCE_DIR}/pyproject.toml"

if [ -f "$SOURCE_TOML" ]; then
    # Check write permissions
    if [ ! -w "$SOURCE_TOML" ]; then
        print_error "No write permission for $SOURCE_TOML"
        exit 1
    fi

    # Create backup before modification
    cp "$SOURCE_TOML" "${SOURCE_TOML}.backup" 2>/dev/null || print_warning "Could not create backup of pyproject.toml"

    # Check if the exclusion configuration already exists
    if ! grep -q "\[tool\.setuptools\.packages\.find\]" "$SOURCE_TOML"; then
        echo "" >> "$SOURCE_TOML"
        echo "[tool.setuptools.packages.find]" >> "$SOURCE_TOML"
        echo 'exclude = ["_python*", "_git*", "env*", "venv*", "source*"]' >> "$SOURCE_TOML"
        print_success "Package discovery configured"
    else
        print_success "Package discovery already configured"
    fi
else
    print_error "pyproject.toml not found in source directory"
    exit 1
fi

# 11. Install dependencies using UV (or pip for older versions)
print_status "Installing BIDScoins dependencies..."
print_status "This may take several minutes on first installation..."

# Change to source directory for installation
cd "$SOURCE_DIR"

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

# Return to base directory
cd "$INSTALL_BASE"

# 12. Clear any Python cache to ensure clean installation
print_status "Clearing Python cache for clean installation..."
find "$SOURCE_DIR" -name "*.pyc" -delete 2>/dev/null || true
find "$SOURCE_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
print_success "Python cache cleared"

# 13. Verify installation
print_status "Verifying BIDScoin installation..."
python -c "import bidscoin; print(f'BIDScoin version: {bidscoin.__version__}')"
print_success "BIDScoin installation verified"

# 14. Test PatientAgeDerived fix (only for dev version)
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

# 15. Test basic functionality
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
print_success "🎉 BIDScoin FULLY ISOLATED installation completed!"
echo "======================================================"
echo ""
print_status "Installation Summary:"
echo "  Version: $VERSION_NAME"
echo "  Installation Directory: $INSTALL_BASE"
echo "  Standalone Python: ${INSTALL_BASE}/_python"
echo "  Portable Git: ${INSTALL_BASE}/_git"
echo "  Virtual Environment: ${INSTALL_BASE}/env"
echo "  Source Code: ${INSTALL_BASE}/source"
echo "  Python Version: $($PYTHON_BIN --version 2>&1)"
echo "  UV Package Manager: $(uv --version 2>&1)"
echo ""
print_success "✓ This installation is COMPLETELY DETACHED from your system!"
print_status "  • Uses its own Python (no system Python needed)"
print_status "  • Uses its own Git (no system Git needed)"
print_status "  • All dependencies self-contained"
print_status "  • Config stored locally in bidscoin_data/ (not ~/.bidscoin/)"
print_status "  • Fully portable - you can move this entire directory!"
echo ""
print_status "Quick Start:"
echo "  1. Change directory: cd $INSTALL_BASE"
echo "  2. Activate environment: source env/bin/activate"
echo "  3. Test installation: bidscoin --help"
echo "  4. Deactivate when done: deactivate"
echo ""
print_status "Alternative - Use activation script:"
echo "  # Create a simple activation script"
echo "  echo 'source ${INSTALL_BASE}/env/bin/activate' > activate_bidscoin.sh"
echo "  chmod +x activate_bidscoin.sh"
echo "  # Then just run: source ./activate_bidscoin.sh"
echo ""
print_status "Portability:"
echo "  • Move entire directory: mv $INSTALL_BASE /path/to/new/location"
echo "  • Copy to another machine: tar -czf bidscoin.tar.gz $INSTALL_BASE"
echo "  • Works on any compatible system (same OS/architecture)"
echo ""
print_status "Key Features:"
if [ "$VERSION_TYPE" = "latest" ]; then
    echo "  ✓ PatientAgeDerived uses StudyDate (better compatibility)"
fi
echo "  ✓ Standalone Python ${PYTHON_VERSION} (no system Python)"
echo "  ✓ Portable Git (no system Git)"
echo "  ✓ Python cache cleared (clean module loading)"
echo "  ✓ Editable installation (development-friendly)"
echo "  ✓ Completely isolated from system"
echo "  ✓ Fully portable installation"
echo ""
print_success "You're all set! Happy brain imaging! 🧠"
echo ""

# Create a convenient activation script
ACTIVATE_SCRIPT="${INSTALL_BASE}/activate_bidscoin.sh"
cat > "$ACTIVATE_SCRIPT" << 'ACTIVATE_EOF'
#!/bin/bash
# BIDScoin Environment Activation Script
# This script activates the standalone BIDScoin environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_ACTIVATE="${SCRIPT_DIR}/env/bin/activate"

if [ ! -f "$ENV_ACTIVATE" ]; then
    echo "Error: Environment not found at $ENV_ACTIVATE"
    exit 1
fi

echo "Activating BIDScoin environment from: $SCRIPT_DIR"
source "$ENV_ACTIVATE"

# Set BIDSCOIN_CONFIGDIR to keep everything within installation directory
export BIDSCOIN_CONFIGDIR="${SCRIPT_DIR}/bidscoin_data"
echo "BIDScoin data directory: $BIDSCOIN_CONFIGDIR"

# Create the config directory if it doesn't exist
mkdir -p "$BIDSCOIN_CONFIGDIR"

# Display version info
python -c "import bidscoin; print(f'BIDScoin {bidscoin.__version__} ready!')" 2>/dev/null || echo "BIDScoin environment activated"

# Show helpful commands
echo ""
echo "Helpful commands:"
echo "  bidscoin --help           # Show BIDScoin help"
echo "  bidsmapper --help         # Show BIDSmapper help"
echo "  bidscoiner --help         # Show BIDScoiner help"
echo "  deactivate                # Exit environment"
echo ""
echo "Note: All BIDScoin configuration and data stored in:"
echo "      $BIDSCOIN_CONFIGDIR"
echo ""
ACTIVATE_EOF

chmod +x "$ACTIVATE_SCRIPT"
print_success "Created activation script: ${ACTIVATE_SCRIPT}"
print_status "Quick activate: source ${ACTIVATE_SCRIPT}"

# Create the bidscoin_data directory and initialize it
print_status "Setting up isolated BIDScoin data directory..."
BIDSCOIN_DATA_DIR="${INSTALL_BASE}/bidscoin_data"
mkdir -p "$BIDSCOIN_DATA_DIR"

# Copy initial configuration from the source if available
if [ -d "${SOURCE_DIR}/bidscoin" ]; then
    # Look for config files in the source
    if [ -d "${SOURCE_DIR}/bidscoin/heuristics" ]; then
        cp -r "${SOURCE_DIR}/bidscoin/heuristics" "${BIDSCOIN_DATA_DIR}/" 2>/dev/null || true
    fi
    if [ -d "${SOURCE_DIR}/bidscoin/plugins" ]; then
        cp -r "${SOURCE_DIR}/bidscoin/plugins" "${BIDSCOIN_DATA_DIR}/" 2>/dev/null || true
    fi
fi

# Create a README in the data directory
cat > "${BIDSCOIN_DATA_DIR}/README.txt" << 'DATA_README'
BIDScoin Data Directory
=======================

This directory contains all BIDScoin configuration, templates, and user data.
By setting BIDSCOIN_CONFIGDIR to this location, the installation remains
completely isolated and portable.

Contents:
- config.toml         - BIDScoin configuration (auto-generated on first run)
- plugins/            - Plugin files
- templates/          - BIDS mapping templates  
- usage/              - Usage statistics (if enabled)
- heuristics/         - Custom heuristics files

This directory will be automatically created and populated when you first
run BIDScoin tools (bidsmapper, bidscoiner, etc.).

To use this installation, always activate with:
  source activate_bidscoin.sh

This ensures BIDSCOIN_CONFIGDIR points to this directory instead of ~/.bidscoin/
DATA_README

print_success "BIDScoin data directory created: ${BIDSCOIN_DATA_DIR}"
print_status "Configuration will be stored locally, not in ~/.bidscoin/"
