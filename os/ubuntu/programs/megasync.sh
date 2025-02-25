#!/bin/bash


# Get the Ubuntu version number
version=$(lsb_release -r | awk '{print $2}')

# Build the download URL
url="https://mega.nz/linux/repo/xUbuntu_${version}/amd64/megasync-xUbuntu_${version}_amd64.deb"

# Update package lists
sudo apt-get update

# Download the Mega Sync Debian package
wget $url

# Install the package
sudo dpkg -i ./megasync-xUbuntu_${version}_amd64.deb

# Remove the package file
rm ./megasync-xUbuntu_${version}_amd64.deb