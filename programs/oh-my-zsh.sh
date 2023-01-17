#!/bin/bash

echo "💻 Installing Oh My Zsh!"

sudo apt-get install -y zsh-common

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "Installing plugins..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

rm ~/.zshrc
ln -s $PWD/.zshrc ~/.zshrc
