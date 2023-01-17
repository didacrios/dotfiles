#!/bin/bash

# Get the system architecture
architecture=$(uname -m)

# Get the Ubuntu version number
version=$(lsb_release -r | awk '{print $2}')

# Build the download URL
url="https://mega.nz/linux/MEGAsync/xUbuntu_${version}/${architecture}/megasync-xUbuntu_${version}_${architecture}.deb"

# Update package lists
sudo apt-get update

# Download the Mega Sync Debian package
wget $url

# Install the package
sudo apt-get install -y ./megasync-xUbuntu_${version}_${architecture}.deb

# Remove the package file
rm megasync-xUbuntu_${version}_${architecture}.deb