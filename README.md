# BIDScoin Installer

A comprehensive installation and version management system for [BIDScoin](https://github.com/Donders-Institute/bidscoin) - a Python toolkit for converting raw MRI data to the Brain Imaging Data Structure (BIDS) standard.

## Overview

This repository provides automated scripts to install, manage, and switch between different versions of BIDScoin with isolated virtual environments. Each version gets its own dedicated environment to prevent conflicts.

## Features

- 🚀 **Automated Installation**: One-command setup for BIDScoin
- 🔄 **Version Management**: Install multiple versions side-by-side
- 🏗️ **Environment Isolation**: Each version gets its own virtual environment
- ⚡ **Fast Package Management**: Uses UV for speedy dependency installation
- 🔧 **Quick Switching**: Easy version switching with environment activation
- ✅ **Verification**: Automatic installation verification and testing
- 🛡️ **Error Recovery**: Automatic cleanup on installation failure
- 💾 **Smart Checks**: Disk space and dependency verification
- 🎯 **Production Ready**: Robust error handling and user feedback

## Quick Start

### Install Latest Stable Version
```bash
./install_bidscoin.sh
```

### Install Latest Development Version
```bash
./install_bidscoin.sh dev
```

### Install Specific Version
```bash
./install_bidscoin.sh 4.6.2
```

### List Available Versions
```bash
./install_bidscoin.sh --list
```

Shows all available BIDScoin versions with recommendations:
- ✅ **✓** = Recommended (latest stable versions)
- ⚠️ **(older)** = Still works but consider upgrading  
- ❌ **(legacy)** = Not recommended (may have compatibility issues)

## Installation Options

| Command | Description | Directory | Environment |
|---------|-------------|-----------|-------------|
| `./install_bidscoin.sh` | Latest stable release | `bidscoin_v4.6.2/` | `bidscoin_v4.6.2_env/` |
| `./install_bidscoin.sh dev` | Latest development | `bidscoin_dev/` | `bidscoin_dev_env/` |
| `./install_bidscoin.sh 4.6.1` | Specific version | `bidscoin_v4.6.1/` | `bidscoin_v4.6.1_env/` |

## Scripts Overview

### `install_bidscoin.sh`
Main installation script that:
1. Clones the BIDScoin repository
2. Switches to the requested version/commit
3. Creates version-specific virtual environment
4. Installs UV package manager for fast dependency installation
5. Installs all BIDScoin dependencies
6. Installs BIDScoin in editable mode
7. Verifies the installation works correctly

**Usage:**
```bash
./install_bidscoin.sh [version|dev]
./install_bidscoin.sh --download    # Download latest script
./install_bidscoin.sh --list        # List all available versions
./install_bidscoin.sh --help        # Show detailed help
```

**Note:** After installation, you can activate any BIDScoin environment directly:
```bash
cd bidscoin_dev                     # Navigate to development version
source bidscoin_dev_env/bin/activate    # Activate the environment
# OR for specific version:
cd bidscoin_v4.6.2                  # Navigate to specific version
source bidscoin_v4.6.2_env/bin/activate # Activate the environment
```

## Requirements

- **Python 3.8+**: Required for BIDScoin
- **Git**: For repository cloning and version management
- **Internet connection**: For downloading dependencies
- **~2GB free disk space**: For installation and dependencies

## Installation Process

The installation script performs these steps:

1. **System Check**: Verifies Python 3, Git, and disk space availability
2. **Repository Clone**: Downloads BIDScoin from GitHub to temporary directory
3. **Version Switch**: Checks out the requested version/commit
4. **Directory Setup**: Moves to final installation directory with proper naming
5. **Environment Setup**: Creates isolated Python virtual environment
6. **Package Manager**: Installs and verifies UV for fast dependency management
7. **Dependencies**: Installs all required and optional dependencies with progress feedback
8. **BIDScoin Install**: Installs BIDScoin in editable development mode
9. **Verification**: Tests the installation and core functionality
10. **Cleanup**: Automatic cleanup on errors, detailed success summary

## Key Features

### Version Isolation
Each BIDScoin version gets its own:
- Source code directory
- Python virtual environment
- Installed dependencies
- Configuration settings

### Fast Installation
Uses [UV package manager](https://github.com/astral-sh/uv) for:
- Faster dependency resolution
- Parallel package installation
- Better caching
- Reduced installation time

### Production Features
The installer includes production-ready features:
- **Error Recovery**: Automatic cleanup of partial installations on failure
- **Progress Feedback**: Clear status updates during long-running operations
- **Smart Validation**: Verifies disk space, dependencies, and installation success
- **Robust Naming**: Stable versions use actual version numbers (e.g., `bidscoin_v4.6.2/`)

### Included Fixes
The installer includes important fixes:
- **PatientAgeDerived**: Uses StudyDate instead of AcquisitionDate for better compatibility
- **Cache Clearing**: Ensures clean Python module loading
- **Dependency Verification**: Confirms all tools are properly installed

## Remote Installation

For systems without this repository, you can install directly:

```bash
bash <(curl -s https://raw.githubusercontent.com/Donders-Institute/bidscoin/master/install_bidscoin.sh)
```

## Post-Installation

After installation, activate your chosen environment:

```bash
cd bidscoin_v4.6.2  # or bidscoin_dev, bidscoin_v4.6.1, etc.
source bidscoin_v4.6.2_env/bin/activate
```

Test the installation:
```bash
bidscoin --help
python -c "import bidscoin; print(bidscoin.__version__)"
```

When finished:
```bash
deactivate
```

## Project Structure

```
bidscoin_installer/
├── install_bidscoin.sh     # Main installation script
├── pyproject.toml          # Project configuration
├── README.md               # This file
├── bidscoin_v4.6.2/        # Stable version installation
├── bidscoin_dev/           # Development version installation
└── bidscoin_v4.6.1/        # Other version installations
```

## Troubleshooting

### Common Issues

1. **Python not found**: Install Python 3.8+ from [python.org](https://python.org)
2. **Git not found**: Install Git from [git-scm.com](https://git-scm.com)
3. **Permission errors**: Ensure you have write permissions in the installation directory
4. **Network issues**: Check internet connection for repository cloning
5. **Disk space**: Ensure at least 2GB free space (installer checks automatically)
6. **Installation failure**: Installer automatically cleans up partial installations

### Error Recovery

The installer includes automatic error recovery:
- **Cleanup on failure**: Removes incomplete installations automatically
- **Progress logging**: Installation logs available for debugging
- **Clear error messages**: Specific guidance for each type of error

### Getting Help

```bash
./install_bidscoin.sh --help    # Detailed installation help
```

## Contributing

This installer is designed to work with the official [BIDScoin repository](https://github.com/Donders-Institute/bidscoin). For BIDScoin issues, please refer to the main project.

## License

This installer follows the same license as BIDScoin (GPL-3.0-or-later).