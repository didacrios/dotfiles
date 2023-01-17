#!/bin/bash

echo "🌎 Installing Chrome Browser"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo apt install ./google-chrome-stable_current_amd64.deb

rm google-chrome-stable_current_amd64.deb

sudo apt-get install -y chrome-gnome-shell