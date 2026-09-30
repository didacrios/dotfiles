#!/bin/bash

# Minimum required OS versions
MIN_UBUNTU_VERSION="24.04"
MIN_MACOS_VERSION="15.3.1"

# Absolute path to the repository, so this script works from any directory.
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Generic setup, shared by every OS, and run before the OS-specific script.
# It must succeed: this script has no `set -e`, so the failure of the OS setup
# that follows would otherwise hide a home directory with no links in it.
# setup: 1 create symlinks
link_dotfiles() {
    echo "🔗 Linking dotfiles into $HOME"
    "$dotfiles_dir/os/symlinks.sh"
}

# Function to compare version numbers
version_ge() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

OS_TYPE="$(uname -s)"

if [[ "$OS_TYPE" == "Linux" ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$ID
        OS_VERSION=$VERSION_ID
        if [[ "$OS_NAME" == "ubuntu" ]]; then
            if version_ge "$OS_VERSION" "$MIN_UBUNTU_VERSION"; then
                echo "Ubuntu version is supported: $OS_VERSION"
                link_dotfiles || exit 1
                exec "$dotfiles_dir/os/ubuntu/setup.sh"
            else
                echo "Ubuntu version is too old. Minimum required is $MIN_UBUNTU_VERSION. Detected: $OS_VERSION"
                exit 1
            fi
        else
            echo "Unsupported Linux distribution: $OS_NAME"
            exit 1
        fi
    else
        echo "Cannot determine Linux distribution. Exiting."
        exit 1
    fi

elif [[ "$OS_TYPE" == "Darwin" ]]; then
    OS_VERSION=$(sw_vers -productVersion)
    if version_ge "$OS_VERSION" "$MIN_MACOS_VERSION"; then
        echo "macOS version is supported: $OS_VERSION"
        link_dotfiles || exit 1
        exec "$dotfiles_dir/os/macos/setup.sh"
    else
        echo "macOS version is too old. Minimum required is $MIN_MACOS_VERSION. Detected: $OS_VERSION"
        exit 1
    fi

else
    echo "Unsupported OS: $OS_TYPE"
    exit 1
fi

# TODO generic setup
# setup: 2 create .local config files ??
# setup: 3 install software brew (mac)
# setup: 4 setup system preferences (mac)
# restart system (mac)