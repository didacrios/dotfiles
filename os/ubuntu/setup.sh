#!/bin/bash

sudo apt update

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo apt install -y $1
  else
    echo "ℹ️  Already installed: ${1}"
  fi
}

# Basics
install curl
install file
install git
install terminator
install htop
install nmap
install openvpn
install keepass2
install calibre
install fzf
install xdotool

# Image processing
install gimp
install inkscape
install jpegoptim
install optipng

# Fun stuff
install figlet
install lolcat

echo "🗨️ Installing slack & discord"
sudo snap install slack
sudo snap install discord

echo "🐋 Installing Docker"
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo docker run hello-world
sudo chmod 666 /var/run/docker.sock

echo "🐋 Installing Docker Compose plugin"
sudo apt-get install -y docker-compose-plugin
docker compose version

echo "💎 Installling Ruby"
sudo apt-get install -y ruby-full
gem install compass

echo "🟢 Installing Node.js via NVM"
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
node -v
npm -v

echo "📦 Installing pnpm"
npm install -g pnpm

echo "🔥 Installing Flameshot GUI screenshot"
echo "You must disable Wayland in gdm3 custom configuration to make flamewshot work"
echo "Set option WaylandEnable=false"
sudo nano /etc/gdm3/custom.conf
sudo apt install flameshot

echo "🎥 Installing Peek screen recorder"
sudo add-apt-repository ppa:peek-developers/stable
sudo apt update -y
sudo apt-get install -y peek

echo "🐘 Installing PhpStorm"
sudo snap install phpstorm --classic


# VSCode removed — not needed.

echo "💿 Installing balenaEtcher"
wget -q https://github.com/balena-io/etcher/releases/download/v2.1.6/balena-etcher_2.1.6_amd64.deb -O /tmp/balena-etcher.deb
sudo dpkg -i /tmp/balena-etcher.deb
sudo apt-get install -f -y
rm /tmp/balena-etcher.deb

echo "🐋 Installing Orca ADE"
# Orca ships as an AppImage: a self-contained asset rather than a system command.
# It is installed per-user in ~/.local/opt and reached through the ~/.local/bin/onorca
# wrapper, which os/symlinks.sh links into place. /usr/local/bin is avoided on
# purpose: a root-owned AppImage cannot replace itself when Orca self-updates.
orca_appimage_dir="$HOME/.local/opt/orca"
orca_appimage="$orca_appimage_dir/orca-linux.AppImage"
# Version-independent asset URL, so the latest release is always installed.
orca_url="https://github.com/stablyai/orca/releases/latest/download/orca-linux.AppImage"

if [ -f "$orca_appimage" ]; then
  echo "ℹ️  Already installed: orca ($orca_appimage)"
else
  echo "⬇️  Downloading the latest orca-linux.AppImage"
  # Download to .part first: a truncated download must never look installed,
  # because $orca_appimage being executable is what the wrapper checks.
  mkdir -p "$orca_appimage_dir"
  if wget -q --show-progress "$orca_url" -O "$orca_appimage.part"; then
    mv "$orca_appimage.part" "$orca_appimage"
    chmod +x "$orca_appimage"
  else
    echo "❌ Orca download failed: $orca_url"
    rm -f "$orca_appimage.part"
  fi
fi

# shell/desktop/orca.desktop looks the icon up by name in the icon theme, so
# extract it from the AppImage itself: it then always matches the installed
# version, with no binary asset to keep in the repository. --appimage-extract
# unpacks into the current directory, hence the temporary one.
orca_icon_source="usr/share/icons/hicolor/512x512/apps/orca-ide.png"
orca_icon="$HOME/.local/share/icons/hicolor/512x512/apps/orca-ide.png"

if [ -x "$orca_appimage" ] && { [ ! -f "$orca_icon" ] || [ "$orca_appimage" -nt "$orca_icon" ]; }; then
  orca_extract_dir="$(mktemp -d)"
  ( cd "$orca_extract_dir" && "$orca_appimage" --appimage-extract "$orca_icon_source" > /dev/null )
  install -Dm644 "$orca_extract_dir/squashfs-root/$orca_icon_source" "$orca_icon"
  rm -rf "$orca_extract_dir"
fi

echo "🔧 Installing Pi (Coding Agent)"
pnpm add -g --ignore-scripts @earendil-works/pi-coding-agent
pi --version
pi --version

echo "🔧 Installing Cursor"
curl -fsSL https://www2.cursor.com/download/linux-deb -o /tmp/cursor.deb
sudo dpkg -i /tmp/cursor.deb
sudo apt-get install -f -y
rm /tmp/cursor.deb

# Create home projects dir :)
if [ ! -d "$HOME/projects" ]; then
  mkdir "$HOME/projects"
  echo "Directory 'projects' created in home directory."
else
  echo "Directory 'projects' already exists in home directory."
fi


# Scripts, shell configs and desktop entries are linked into $HOME by
# os/symlinks.sh, which the root setup.sh runs as its generic "create symlinks"
# step before dispatching to this script.

figlet "Welcome back!" | lolcat

echo "You may want to set some settings manually"
echo " ☐ PHP settings "
echo " ☐ ssh configuration "
echo " ☐ Generate ssh private keys "
echo " ☐ Clone your projects in $HOME/projects"

# symfony
# echo "🐘 Installing symfony and PHP"
#wget https://get.symfony.com/cli/installer -O - | bash
#export PATH="$HOME/.symfony/bin:$PATH".
#source ~/.bashrc
