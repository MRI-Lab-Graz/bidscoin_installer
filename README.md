# BIDScoin Installer

A comprehensive installation and version management system for [BIDScoin](https://github.com/Donders-Institute/bidscoin) - a Python toolkit for converting raw MRI data to the Brain Imaging Data Structure (BIDS) standard.

## ⚠️ IMPORTANT: Data Privacy & Security

**This installer is for software distribution only. Do NOT commit any patient or subject data to this repository.**

### Protected Data Types
- DICOM files (`.dcm`)
- NIfTI files (`.nii`, `.nii.gz`)
- Participant information (`participants.tsv`, `participants.json`)
- Subject directories (`sub-*`, `ses-*`)
- Any files containing patient identifiers

### Data Handling
- Use the `rawdata/` and `sourcedata/` directories locally only
- These directories are automatically ignored by Git
- Always review files before committing
- Follow your institution's data protection guidelines

## Overview

This repository provides automated scripts to install, manage, and switch between different versions of BIDScoin with isolated virtual environments. Each version gets its own dedicated environment to prevent conflicts.

## Features

- 🚀 **Automated Installation**: One-command setup for BIDScoin
- 🔄 **Version Management**: Install multiple versions side-by-side
- 🏗️ **Environment Isolation**: Each version gets its own virtual environment
- ⚡ **Fast Package Management**: Uses UV for speedy dependency installation
- 🔧 **Quick Switching**: Easy version switching with environment activation
- ✅ **Verification**: Automatic installation verification and testing

## Quick Start

### Install Latest Stable Version
```bash
./install_bidscoin.sh
```

### Install Latest Development Version
```bash
./install_bidscoin.sh latest
```

### Install Specific Version
```bash
./install_bidscoin.sh 4.6.2
```

## Installation Options

| Command | Description | Directory | Environment |
|---------|-------------|-----------|-------------|
| `./install_bidscoin.sh` | Latest stable release | `bidscoin_stable/` | `bidscoin_stable_env/` |
| `./install_bidscoin.sh latest` | Latest development | `bidscoin_latest/` | `bidscoin_latest_env/` |
| `./install_bidscoin.sh 4.6.2` | Specific version | `bidscoin_v4.6.2/` | `bidscoin_v4.6.2_env/` |

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
./install_bidscoin.sh [version|latest]
./install_bidscoin.sh --download    # Download latest script
./install_bidscoin.sh --help        # Show detailed help
```

### `use_bidscoin.sh`
Quick switcher that activates a specific BIDScoin version and its environment:
```bash
source ./use_bidscoin.sh latest     # Switch to latest and activate environment
source ./use_bidscoin.sh stable     # Switch to stable and activate environment
source ./use_bidscoin.sh 4.6.2      # Switch to specific version
```

### `switch_version.sh`
Advanced version management with virtual environment support:
```bash
./switch_version.sh latest          # Switch to latest development
./switch_version.sh stable          # Switch to stable release
./switch_version.sh 4.6.1           # Switch to specific version
./switch_version.sh list            # List available versions
./switch_version.sh list-envs       # List virtual environments
./switch_version.sh current         # Show current version
```

## Requirements

- **Python 3.8+**: Required for BIDScoin
- **Git**: For repository cloning and version management
- **Internet connection**: For downloading dependencies

## Installation Process

The installation script performs these steps:

1. **System Check**: Verifies Python 3 and Git are installed
2. **Repository Clone**: Downloads BIDScoin from GitHub
3. **Version Switch**: Checks out the requested version/commit
4. **Environment Setup**: Creates isolated Python virtual environment
5. **Package Manager**: Installs UV for fast dependency management
6. **Dependencies**: Installs all required and optional dependencies
7. **BIDScoin Install**: Installs BIDScoin in editable development mode
8. **Verification**: Tests the installation and core functionality

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

### Included Fixes
The installer includes important fixes:
- **PatientAgeDerived**: Uses StudyDate instead of AcquisitionDate for better compatibility
- **Anonymization**: Disabled by default to preserve patient data
- **Cache Clearing**: Ensures clean Python module loading

## Remote Installation

For systems without this repository, you can install directly:

```bash
bash <(curl -s https://raw.githubusercontent.com/Donders-Institute/bidscoin/master/install_bidscoin.sh)
```

## Post-Installation

After installation, activate your chosen environment:

```bash
cd bidscoin_stable  # or bidscoin_latest, bidscoin_v4.6.2, etc.
source bidscoin_stable_env/bin/activate
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
├── use_bidscoin.sh         # Quick environment switcher
├── switch_version.sh       # Advanced version management
├── pyproject.toml          # Project configuration
├── README.md               # This file
├── bidscoin_stable/        # Stable version installation
├── bidscoin_latest/        # Latest development installation
├── bidscoin_v4.6.2/        # Specific version installation
└── rawdata/                # Sample data directory
```

## Troubleshooting

### Common Issues

1. **Python not found**: Install Python 3.8+ from [python.org](https://python.org)
2. **Git not found**: Install Git from [git-scm.com](https://git-scm.com)
3. **Permission errors**: Ensure you have write permissions in the installation directory
4. **Network issues**: Check internet connection for repository cloning

### Getting Help

```bash
./install_bidscoin.sh --help    # Detailed installation help
./switch_version.sh --help      # Version management help
```

## Contributing

This installer is designed to work with the official [BIDScoin repository](https://github.com/Donders-Institute/bidscoin). For BIDScoin issues, please refer to the main project.

## License

This installer follows the same license as BIDScoin (GPL-3.0-or-later).