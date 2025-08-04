#!/bin/bash

# BIDScoin Quick Switcher
# This is a convenience wrapper for switching BIDScoin versions and auto-activating environments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCH_SCRIPT="$SCRIPT_DIR/switch_version.sh"

if [ ! -f "$SWITCH_SCRIPT" ]; then
    echo "[ERROR] switch_version.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Function to show usage
show_usage() {
    echo "BIDScoin Quick Switcher"
    echo ""
    echo "This script switches BIDScoin versions and automatically activates the virtual environment."
    echo "Run this with 'source' to activate the environment in your current shell."
    echo ""
    echo "Usage: source $0 <version>"
    echo ""
    echo "Examples:"
    echo "  source $0 latest    # Switch to latest development version"
    echo "  source $0 stable    # Switch to latest stable release"
    echo "  source $0 4.6.2     # Switch to specific version"
    echo ""
    echo "After running, you'll be in the virtual environment for that version."
    echo "To deactivate: deactivate"
}

# Check if no arguments provided
if [ $# -eq 0 ]; then
    show_usage
    return 1 2>/dev/null || exit 1
fi

# Check for help
if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    return 0 2>/dev/null || exit 0
fi

# Check if script is being sourced (required for environment activation)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "[WARNING] This script should be sourced to activate the virtual environment"
    echo "[WARNING] Use: source $0 $1"
    echo ""
    echo "Running in sub-shell mode (environment won't persist)..."
    echo ""
fi

# Generate and execute the activation script
eval "$("$SWITCH_SCRIPT" use "$1")"
