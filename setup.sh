#!/bin/bash

sudo apt update

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo apt install -y $1
  else
    echo "Already installed: ${1}"
  fi
}

# Basics
install curl
install file
install git
install terminator
install htop
install nmap
install slack
install openvpn
install keepass2

# Image processing
install gimp
install inkscape
install jpegoptim
install optipng

# Fun stuff
install figlet
install lolcat

figlet "Basic setup finished!" | lolcat

OVPN_CERTIFICATE="files/didac.rios.openvpn"
# Move OVPN certificate to new path
if [ -f $OVPN_CERTIFICATE]; then
  sudo cp files/didac.rios.openvpn /etc/openvpn/client.conf
  sudo chmod +755 /etc/openvpn/client.conf
  sudo systemctl daemon-reload
fi

# Install Docker
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

# Installing Docker Compose
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
sudo apt install flameshot

echo "🎥 Installing Peek screen recorder"
sudo add-apt-repository ppa:peek-developers/stable
sudo apt update -y
sudo apt-fast install -y peek

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

# TODO: Veure si això ho podem solventar amb el settings sync del IDE
echo "Installing VSCodeExtensions"
code --install-extension alefragnani.project-manager
code --install-extension alexkrechik.cucumberautocomplete
code --install-extension aswinkumar863.smarty-template-support
code --install-extension atlassian.atlascode
code --install-extension bmewburn.vscode-intelephense-client
code --install-extension DavidAnson.vscode-markdownlint
code --install-extension donjayamanne.githistory
code --install-extension duboiss.sf-pack
code --install-extension eamodio.gitlens
code --install-extension EditorConfig.EditorConfig
code --install-extension esbenp.prettier-vscode
code --install-extension Glavin001.unibeautify-vscode
code --install-extension imperez.smarty
code --install-extension mblode.twig-language-2
code --install-extension michelemelluso.code-beautifier
code --install-extension mikestead.dotenv
code --install-extension mkloubert.vscode-deploy-reloaded
code --install-extension mrorz.language-gettext
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-mssql.data-workspace-vscode
code --install-extension ms-mssql.mssql
code --install-extension ms-mssql.sql-bindings-vscode
code --install-extension ms-mssql.sql-database-projects-vscode
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension ms-vsliveshare.vsliveshare
code --install-extension ms-vsliveshare.vsliveshare-audio
code --install-extension nadim-vscode.symfony-code-snippets
code --install-extension nadim-vscode.symfony-super-console
code --install-extension octref.vetur
code --install-extension phproberto.vscode-php-getters-setters
code --install-extension redhat.vscode-commons
code --install-extension redhat.vscode-yaml
code --install-extension rexshi.phpdoc-comment-vscode-plugin
code --install-extension ryu1kn.partial-diff
code --install-extension SimonSiefke.prettier-vscode
code --install-extension stevejpurves.cucumber
code --install-extension TheNouillet.symfony-vscode
code --install-extension wayou.vscode-todo-highlight
code --install-extension whatwedo.twig
code --install-extension Wscats.eno
code --install-extension xdebug.php-debug
code --install-extension xdebug.php-pack
code --install-extension YoshinoriN.current-file-path
code --install-extension zobo.php-intellisense

# Create home projects dir :)
if [ ! -d "$HOME/projects" ]; then
  mkdir "$HOME/projects"
  echo "Directory 'projects' created in home directory."
else
  echo "Directory 'projects' already exists in home directory."
fi

figlet "Welcome back!" | lolcat
