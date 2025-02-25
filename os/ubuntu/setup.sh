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

echo "🐋 Installing Docker Compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "💎 Installling Ruby"
sudo apt-get install -y ruby-full
gem install compass

echo "🟢 Installing nodeJS"
sudo apt-get install -y nodejs
node -v

echo "📦 Installing npm"
sudo apt-get install -y npm
npm -v

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


echo "⌨️  Installing VSCode"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt install -y apt-transport-https
sudo apt update
sudo apt install -y code
rm microsoft.gpg



# Create home projects dir :)
if [ ! -d "$HOME/projects" ]; then
  mkdir "$HOME/projects"
  echo "Directory 'projects' created in home directory."
else
  echo "Directory 'projects' already exists in home directory."
fi


# Move scripts to bin
scripts_dir="scripts"
scripts_dir_destination="/usr/local/bin"

for script_file in "$source_dir"/*.sh; do
  script_name=$(basename "$script_file")
  ln -s "$(realpath "$script_file")" "$destination_dir/$script_name"
  echo "Adding script globaly $script_file
done




figlet "Welcome back!" | lolcat

echo "You may want to set some settings manually"
echo " ☐ VSCode settings "
echo " ☐ PHP settings "
echo " ☐ ssh configuration "
echo " ☐ Generate ssh private keys "
echo " ☐ Clone your projects in $HOME/projects"

# symfony
# echo "🐘 Installing symfony and PHP"
#wget https://get.symfony.com/cli/installer -O - | bash
#export PATH="$HOME/.symfony/bin:$PATH".
#source ~/.bashrc
