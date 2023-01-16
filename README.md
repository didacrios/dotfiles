# dotfiles

dotfiles project for apt package managers

## Global GIT configuration

`~/.gitconfig` as a global config, override in each git repository

## Connect with GIT repositories

```bash
ssh-keygen -o -t rsa -C "your@email.com" -b 4096
```

This will generate a private and public key in `~/.ssh/id_rsa.pub` that must be added into the ssh keys settings for your user in git platform in order to clone the projects.

