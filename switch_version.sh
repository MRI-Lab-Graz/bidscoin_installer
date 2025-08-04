#!/bin/bash

# BIDScoin Version Management Script with Virtual Environment Support
# This script helps you switch between different versions of BIDScoin
# Each version gets its own isolated virtual environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIDSCOIN_DIR="$SCRIPT_DIR"
VENV_DIR="$SCRIPT_DIR/.venvs"
CURRENT_VENV_FILE="$SCRIPT_DIR/.current_venv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to show usage
show_usage() {
    echo "BIDScoin Version Management Script with Virtual Environment Support"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  latest              Switch to the latest commit from main branch"
    echo "  stable              Switch to the latest stable release (4.6.2)"
    echo "  <version>           Switch to a specific version (e.g., 4.6.1, 4.5.0)"
    echo "  list                List all available versions"
    echo "  list-envs           List all created virtual environments"
    echo "  current             Show current version/branch"
    echo "  install             Install current version in dedicated virtual environment"
    echo "  activate <version>  Show command to activate specific environment"
    echo "  clean <version>     Remove virtual environment for specific version"
    echo "  clean-all           Remove all virtual environments"
    echo "  setup-remote        Set up origin remote to official BIDScoin repository"
    echo "  use <version>       Generate activation script for version (source the output)"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 latest           # Switch to latest development code"
    echo "  $0 stable           # Switch to latest stable release"
    echo "  $0 4.6.1            # Switch to version 4.6.1"
    echo "  $0 install          # Install current version in dedicated venv"
    echo "  $0 activate 4.6.2   # Show activation command for version 4.6.2"
    echo "  $0 list-envs        # Show all created environments"
    echo "  $0 clean 4.6.1      # Remove environment for version 4.6.1"
    echo "  $0 setup-remote     # Set up connection to official BIDScoin repository"
    echo "  source <($0 use 4.6.2)  # Switch to version 4.6.2 and activate its venv"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "This directory is not a git repository"
        exit 1
    fi
}

# Function to get current branch/tag
get_current_version() {
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    local current_tag=$(git describe --exact-match --tags HEAD 2>/dev/null || echo "")
    
    if [ -n "$current_tag" ]; then
        echo "$current_tag"
    elif [ -n "$current_branch" ]; then
        echo "$current_branch"
    else
        echo "unknown"
    fi
}

# Function to get virtual environment name for a version
get_venv_name() {
    local version="$1"
    
    # For branch names (like main/master), we want to include commit info
    # to make different commits have different environments
    if git show-ref --verify --quiet "refs/heads/$version" 2>/dev/null; then
        # This is a branch name, add commit hash for uniqueness
        local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        local commit_date=$(git log -1 --format="%Y%m%d" 2>/dev/null || echo "unknown")
        echo "bidscoin_${version}_${commit_date}_${commit_hash}"
    else
        # This is likely a tag or specific version
        echo "bidscoin_${version}"
    fi
}

# Function to get a display-friendly version name
get_display_version() {
    local version="$1"
    
    if git show-ref --verify --quiet "refs/heads/$version" 2>/dev/null; then
        # This is a branch name, add commit info for clarity
        local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        local commit_date=$(git log -1 --format="%Y-%m-%d" 2>/dev/null || echo "unknown")
        echo "$version ($commit_date $commit_hash)"
    else
        # This is likely a tag or specific version
        echo "$version"
    fi
}

# Function to get virtual environment path
get_venv_path() {
    local version="$1"
    local venv_name=$(get_venv_name "$version")
    echo "$VENV_DIR/$venv_name"
}

# Function to create virtual environment directory
ensure_venv_dir() {
    if [ ! -d "$VENV_DIR" ]; then
        print_status "Creating virtual environments directory: $VENV_DIR"
        mkdir -p "$VENV_DIR"
    fi
}

# Function to create virtual environment for a version
create_venv() {
    local version="$1"
    local venv_path=$(get_venv_path "$version")
    
    ensure_venv_dir
    
    if [ -d "$venv_path" ]; then
        print_status "Virtual environment for $version already exists"
        return 0
    fi
    
    print_status "Creating virtual environment for BIDScoin $version..."
    python3 -m venv "$venv_path"
    
    if [ ! -d "$venv_path" ]; then
        print_error "Failed to create virtual environment"
        return 1
    fi
    
    print_status "Virtual environment created successfully"
    return 0
}

# Function to activate virtual environment and install BIDScoin
install_in_venv() {
    local version="$1"
    local venv_path=$(get_venv_path "$version")
    
    if [ ! -d "$venv_path" ]; then
        print_error "Virtual environment for $version not found. Run install first."
        return 1
    fi
    
    print_status "Installing BIDScoin $version in virtual environment..."
    
    # Activate virtual environment and install
    source "$venv_path/bin/activate"
    
    # Upgrade pip first
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install BIDScoin in development mode from the current directory
    print_status "Installing BIDScoin in development mode..."
    cd "$BIDSCOIN_DIR"
    pip install -e .
    
    # Verify installation
    if python -c "import bidscoin" 2>/dev/null; then
        print_status "BIDScoin $version installed successfully"
    else
        print_error "BIDScoin installation verification failed"
        deactivate
        return 1
    fi
    
    # Save current environment info
    echo "$version" > "$CURRENT_VENV_FILE"
    
    deactivate
    return 0
}

# Function to list virtual environments
list_environments() {
    print_header "Created BIDScoin virtual environments:"
    echo ""
    
    if [ ! -d "$VENV_DIR" ]; then
        print_status "No virtual environments created yet"
        return 0
    fi
    
    local found_any=false
    for venv_dir in "$VENV_DIR"/bidscoin_*; do
        if [ -d "$venv_dir" ]; then
            found_any=true
            local venv_name=$(basename "$venv_dir")
            local version=${venv_name#bidscoin_}
            local status=""
            
            # Check if this is the current environment
            if [ -f "$CURRENT_VENV_FILE" ]; then
                local current_version=$(cat "$CURRENT_VENV_FILE" 2>/dev/null || echo "")
                if [ "$version" = "$current_version" ]; then
                    status=" (current)"
                fi
            fi
            
            # Create a more readable version name
            local display_name="$version"
            if [[ "$version" =~ ^(main|master)_[0-9]+_[a-f0-9]+$ ]]; then
                # This is a branch with date and commit hash
                local branch=$(echo "$version" | cut -d'_' -f1)
                local date=$(echo "$version" | cut -d'_' -f2)
                local hash=$(echo "$version" | cut -d'_' -f3)
                # Format date from YYYYMMDD to YYYY-MM-DD
                local formatted_date="${date:0:4}-${date:4:2}-${date:6:2}"
                display_name="$branch ($formatted_date $hash)"
            fi
            
            echo "  $display_name$status"
            echo "    Path: $venv_dir"
            echo "    Activation: source $venv_dir/bin/activate"
            echo ""
        fi
    done
    
    if [ "$found_any" = false ]; then
        print_status "No virtual environments found"
    fi
}

# Function to show activation command
show_activate_command() {
    local version="$1"
    local venv_path=$(get_venv_path "$version")
    
    if [ ! -d "$venv_path" ]; then
        print_error "Virtual environment for $version not found"
        print_status "Use '$0 install' after switching to $version to create it"
        return 1
    fi
    
    print_header "To activate BIDScoin $version environment:"
    echo ""
    echo "source $venv_path/bin/activate"
    echo ""
    print_status "After activation, you can use all bidscoin commands"
    print_status "To deactivate, simply run: deactivate"
}

# Function to generate activation script for a version
generate_use_script() {
    local version="$1"
    local script_dir="$SCRIPT_DIR"
    
    # Switch to the version first (but suppress output for cleaner sourcing)
    cd "$script_dir"
    
    case "$version" in
        "latest")
            switch_to_latest > /dev/null 2>&1 || {
                echo "echo '[ERROR] Failed to switch to latest version'" >&2
                return 1
            }
            version=$(get_current_version)
            ;;
        "stable")
            switch_to_stable > /dev/null 2>&1 || {
                echo "echo '[ERROR] Failed to switch to stable version'" >&2
                return 1
            }
            version=$(get_current_version)
            ;;
        *)
            # Check if it's a specific version
            if git rev-parse --verify "refs/tags/$version" > /dev/null 2>&1; then
                git checkout "$version" > /dev/null 2>&1 || {
                    echo "echo '[ERROR] Failed to switch to version $version'" >&2
                    return 1
                }
            else
                echo "echo '[ERROR] Version $version not found'" >&2
                return 1
            fi
            ;;
    esac
    
    local venv_path=$(get_venv_path "$version")
    
    # Generate the activation script
    cat << EOF
# BIDScoin version switcher - auto-generated script
cd "$script_dir"

# Check if virtual environment exists
if [ ! -d "$venv_path" ]; then
    echo "[INFO] Virtual environment for $version not found. Creating and installing..."
    # Create and install if needed
    python3 -m venv "$venv_path" && \\
    source "$venv_path/bin/activate" && \\
    pip install --upgrade pip > /dev/null 2>&1 && \\
    cd "$script_dir" && \\
    pip install -e . > /dev/null 2>&1 && \\
    echo "[INFO] BIDScoin $version installed successfully"
else
    echo "[INFO] Activating BIDScoin $version environment"
    source "$venv_path/bin/activate"
    
    # Verify BIDScoin is installed, if not install it
    if ! python -c "import bidscoin" > /dev/null 2>&1; then
        echo "[INFO] BIDScoin not found in environment, installing..."
        cd "$script_dir"
        pip install -e . > /dev/null 2>&1
        echo "[INFO] BIDScoin $version installed successfully"
    fi
fi

# Update current environment tracking
echo "$version" > "$CURRENT_VENV_FILE"

echo "[INFO] Now using BIDScoin $version"
echo "[INFO] Virtual environment: $venv_path"
echo "[INFO] To deactivate, run: deactivate"
EOF
}

# Function to clean virtual environment
clean_venv() {
    local version="$1"
    local venv_path=$(get_venv_path "$version")
    
    if [ ! -d "$venv_path" ]; then
        print_warning "Virtual environment for $version not found"
        return 0
    fi
    
    print_status "Removing virtual environment for $version..."
    rm -rf "$venv_path"
    
    # Clear current environment if it was the one we just removed
    if [ -f "$CURRENT_VENV_FILE" ]; then
        local current_version=$(cat "$CURRENT_VENV_FILE" 2>/dev/null || echo "")
        if [ "$version" = "$current_version" ]; then
            rm -f "$CURRENT_VENV_FILE"
        fi
    fi
    
    print_status "Virtual environment for $version removed successfully"
}

# Function to clean all virtual environments
clean_all_venvs() {
    if [ ! -d "$VENV_DIR" ]; then
        print_status "No virtual environments to clean"
        return 0
    fi
    
    print_warning "This will remove ALL BIDScoin virtual environments"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing all virtual environments..."
        rm -rf "$VENV_DIR"
        rm -f "$CURRENT_VENV_FILE"
        print_status "All virtual environments removed successfully"
    else
        print_status "Operation cancelled"
    fi
}

# Function to set up remote repository
setup_remote() {
    print_header "Setting up remote repository connection"
    
    # Check if origin already exists
    if git remote get-url origin > /dev/null 2>&1; then
        local current_origin=$(git remote get-url origin)
        print_status "Origin remote already exists: $current_origin"
        
        read -p "Do you want to update it to the official BIDScoin repository? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Updating origin remote..."
            git remote set-url origin https://github.com/Donders-Institute/bidscoin.git
        else
            print_status "Keeping current remote unchanged"
            return 0
        fi
    else
        print_status "Adding origin remote for official BIDScoin repository..."
        git remote add origin https://github.com/Donders-Institute/bidscoin.git
    fi
    
    print_status "Testing connection to remote repository..."
    if git ls-remote origin > /dev/null 2>&1; then
        print_status "Successfully connected to remote repository"
        print_status "You can now use 'latest' and 'stable' options to get the newest versions"
        
        # Fetch tags and branches
        print_status "Fetching tags and branches..."
        git fetch origin
        git fetch --tags
        
        print_status "Remote setup complete!"
    else
        print_error "Failed to connect to remote repository"
        print_error "Please check your internet connection"
    fi
}

# Function to list available versions
list_versions() {
    print_header "Available BIDScoin versions:"
    echo ""
    
    # Check if origin remote exists and try to fetch tags
    if git remote get-url origin > /dev/null 2>&1; then
        print_status "Fetching latest information from remote..."
        if ! git fetch --tags > /dev/null 2>&1; then
            print_warning "Failed to fetch from remote. Showing local versions only."
        fi
    else
        print_warning "No 'origin' remote found. Showing local versions only."
    fi
    
    local tags=$(git tag -l --sort=-version:refname)
    
    if [ -z "$tags" ]; then
        print_warning "No version tags found"
        echo "Available branches:"
        git branch -a | sed 's/^/  /'
    else
        echo "Recent stable releases:"
        echo "$tags" | head -10 | while read tag; do
            echo "  $tag"
        done
        
        if [ $(echo "$tags" | wc -l) -gt 10 ]; then
            echo "  ... and $(( $(echo "$tags" | wc -l) - 10 )) more"
        fi
    fi
    
    echo ""
    echo "Special options:"
    echo "  latest    - Latest commit from main branch"
    local latest_tag=$(echo "$tags" | head -1)
    if [ -n "$latest_tag" ]; then
        echo "  stable    - Latest stable release ($latest_tag)"
    else
        echo "  stable    - Latest stable release (no tags found)"
    fi
}

# Function to switch to latest commit
switch_to_latest() {
    print_status "Switching to latest commit from main branch..."
    
    # Check if origin remote exists
    if ! git remote get-url origin > /dev/null 2>&1; then
        print_warning "No 'origin' remote found. Working with local repository only."
        
        # Check if main branch exists locally
        if git show-ref --verify --quiet refs/heads/main; then
            print_status "Switching to local main branch..."
            git checkout main
            print_status "Successfully switched to main branch (local)"
        elif git show-ref --verify --quiet refs/heads/master; then
            print_status "Main branch not found, switching to master branch..."
            git checkout master
            print_status "Successfully switched to master branch (local)"
        else
            print_error "Neither main nor master branch found"
            exit 1
        fi
    else
        # Origin remote exists, fetch and pull
        print_status "Fetching from origin..."
        if ! git fetch origin; then
            print_error "Failed to fetch from origin. Check your network connection and access rights."
            exit 1
        fi
        
        print_status "Switching to main branch..."
        git checkout main
        
        print_status "Pulling latest changes..."
        if ! git pull origin main; then
            print_error "Failed to pull from origin main. You may need to resolve conflicts."
            exit 1
        fi
        
        print_status "Successfully switched to latest development version"
    fi
    
    print_status "Current commit: $(git rev-parse --short HEAD)"
}

# Function to switch to stable version
switch_to_stable() {
    print_status "Fetching latest tags..."
    
    # Check if origin remote exists
    if git remote get-url origin > /dev/null 2>&1; then
        if ! git fetch --tags; then
            print_warning "Failed to fetch tags from remote. Using local tags only."
        fi
    else
        print_warning "No 'origin' remote found. Using local tags only."
    fi
    
    local latest_tag=$(git tag -l --sort=-version:refname | head -1)
    
    if [ -z "$latest_tag" ]; then
        print_error "No stable releases found"
        print_status "Available tags: $(git tag -l | tr '\n' ' ')"
        exit 1
    fi
    
    print_status "Switching to latest stable release: $latest_tag"
    git checkout "$latest_tag"
    
    print_status "Successfully switched to stable version $latest_tag"
}

# Function to switch to specific version
switch_to_version() {
    local version="$1"
    
    print_status "Fetching latest tags..."
    
    # Check if origin remote exists and try to fetch tags
    if git remote get-url origin > /dev/null 2>&1; then
        if ! git fetch --tags; then
            print_warning "Failed to fetch tags from remote. Using local tags only."
        fi
    else
        print_warning "No 'origin' remote found. Using local tags only."
    fi
    
    # Check if version exists
    if ! git rev-parse --verify "refs/tags/$version" > /dev/null 2>&1; then
        print_error "Version $version not found"
        print_status "Available local tags: $(git tag -l | tr '\n' ' ')"
        print_status "Use '$0 list' to see available versions"
        exit 1
    fi
    
    print_status "Switching to version $version..."
    git checkout "$version"
    
    print_status "Successfully switched to version $version"
}

# Function to install current version
install_current() {
    local current_version=$(get_current_version)
    
    print_status "Installing BIDScoin $current_version in dedicated virtual environment..."
    
    # Check if python3 is available
    if ! command -v python3 > /dev/null 2>&1; then
        print_error "python3 not found. Please make sure Python 3 is installed."
        exit 1
    fi
    
    # Create virtual environment
    if ! create_venv "$current_version"; then
        print_error "Failed to create virtual environment"
        exit 1
    fi
    
    # Install in virtual environment
    if ! install_in_venv "$current_version"; then
        print_error "Failed to install BIDScoin"
        exit 1
    fi
    
    print_status "BIDScoin $current_version installed successfully in dedicated environment"
    echo ""
    print_header "To use this installation:"
    show_activate_command "$current_version"
}

# Function to show current version
show_current() {
    local current=$(get_current_version)
    local commit_hash=$(git rev-parse --short HEAD)
    
    print_header "Current BIDScoin version information:"
    echo "  Version/Branch: $current"
    echo "  Commit: $commit_hash"
    echo "  Repository: $(git remote get-url origin 2>/dev/null || echo 'No remote')"
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warning "You have uncommitted changes"
    fi
    
    echo ""
    
    # Show virtual environment info
    local venv_path=$(get_venv_path "$current")
    if [ -d "$venv_path" ]; then
        print_status "Virtual environment exists for this version"
        echo "  Environment path: $venv_path"
        echo "  Activation command: source $venv_path/bin/activate"
    else
        print_warning "No virtual environment found for this version"
        print_status "Use '$0 install' to create and install in dedicated environment"
    fi
    
    # Show current active environment if any
    if [ -f "$CURRENT_VENV_FILE" ]; then
        local current_env_version=$(cat "$CURRENT_VENV_FILE" 2>/dev/null || echo "")
        if [ -n "$current_env_version" ]; then
            echo ""
            print_status "Last installed environment: $current_env_version"
        fi
    fi
}

# Main script logic
main() {
    cd "$BIDSCOIN_DIR"
    check_git_repo
    
    case "${1:-help}" in
        "latest")
            switch_to_latest
            ;;
        "stable")
            switch_to_stable
            ;;
        "list")
            list_versions
            ;;
        "list-envs")
            list_environments
            ;;
        "current")
            show_current
            ;;
        "install")
            install_current
            ;;
        "activate")
            if [ -z "$2" ]; then
                print_error "Please specify a version to activate"
                print_status "Usage: $0 activate <version>"
                exit 1
            fi
            show_activate_command "$2"
            ;;
        "clean")
            if [ -z "$2" ]; then
                print_error "Please specify a version to clean"
                print_status "Usage: $0 clean <version>"
                exit 1
            fi
            clean_venv "$2"
            ;;
        "clean-all")
            clean_all_venvs
            ;;
        "setup-remote")
            setup_remote
            ;;
        "use")
            if [ -z "$2" ]; then
                print_error "Please specify a version to use"
                print_status "Usage: source <($0 use <version>)"
                print_status "Examples:"
                print_status "  source <($0 use latest)"
                print_status "  source <($0 use stable)"
                print_status "  source <($0 use 4.6.2)"
                exit 1
            fi
            generate_use_script "$2"
            exit 0
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            # Assume it's a version number
            switch_to_version "$1"
            ;;
    esac
    
    echo ""
    local current=$(get_current_version)
    print_status "Current git version: $current"
    
    local venv_path=$(get_venv_path "$current")
    if [ -d "$venv_path" ]; then
        print_status "Virtual environment available for this version"
        print_status "Use '$0 activate $current' to see activation command"
    else
        print_status "Use '$0 install' to create dedicated virtual environment"
    fi
}

# Run main function with all arguments
main "$@"
