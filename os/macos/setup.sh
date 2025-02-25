#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

brew_install() {

    declare -r ARGUMENTS="$3"
    declare -r FORMULA="$2"
    declare -r FORMULA_READABLE_NAME="$1"
    declare -r TAP_VALUE="$4"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if `Homebrew` is installed.

    if ! cmd_exists "brew"; then
        print_error "$FORMULA_READABLE_NAME ('Homebrew' is not installed)"
        return 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If `brew tap` needs to be executed,
    # check if it executed correctly.

    if [ -n "$TAP_VALUE" ]; then
        if ! brew_tap "$TAP_VALUE"; then
            print_error "$FORMULA_READABLE_NAME ('brew tap $TAP_VALUE' failed)"
            return 1
        fi
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Install the specified formula.

    # shellcheck disable=SC2086
    if brew list "$FORMULA" &> /dev/null; then
        print_success "$FORMULA_READABLE_NAME"
    else
        execute \
            "brew install $FORMULA $ARGUMENTS" \
            "$FORMULA_READABLE_NAME"
    fi

}

brew_prefix() {

    local path=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if path="$(brew --prefix 2> /dev/null)"; then
        printf "%s" "$path"
        return 0
    else
        print_error "Homebrew (get prefix)"
        return 1
    fi

}

brew_tap() {
    brew tap "$1" &> /dev/null
}

brew_update() {

    execute \
        "brew update" \
        "Homebrew (update)"

}

brew_upgrade() {

    execute \
        "brew upgrade" \
        "Homebrew (upgrade)"

}

# Ensure Homebrew is installed
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Updating Homebrew..."
brew update

# Install packages
BREW_PACKAGES=(
    zsh
    docker
    docker-completion
    rust
)

CASK_PACKAGES=(
    karabiner-elements
    visual-studio-code
    raycast
    intellij-idea-ce
    warp
    arc
    google-chrome
    firefox
    brave-browser
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
)

echo "Installing brew packages..."
brew install "${BREW_PACKAGES[@]}"

echo "Installing cask packages..."
brew install --cask "${CASK_PACKAGES[@]}"

# Install oh-my-zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


# Configure .zshrc
echo "Configuring Zsh theme and plugins..."
ZSHRC="$HOME/.zshrc"

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k


# Install fnm (Fast Node Manager)
echo "Installing fnm..."
brew install fnm

# Configure p10k
echo "Configuring powerlevel10k..."
p10k configure

# Copy .gitconfig and gitignore to home directory
echo "Copying .gitconfig and .gitignore to home directory..."
cp -iV .gitconfig $HOME
cp -iV .gitignore $HOME


grep -qxF "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" "$ZSHRC" || echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> "$ZSHRC"
grep -qxF "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "$ZSHRC" || echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$ZSHRC"
grep -qxF "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" "$ZSHRC" || echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$ZSHRC"

source "$ZSHRC"

# ask fot global git username and replace CHANGEME_GIT_NAME and CHANGEME_GIT_EMAIL with input in copied .gitconfig
echo "Enter your global git username:"
read GIT_USERNAME
sed -i '' "s/CHANGEME_GIT_NAME/$GIT_USERNAME/g" $HOME/.gitconfig

echo "Enter your global git email:"
read GIT_EMAIL
sed -i '' "s/CHANGEME_GIT_EMAIL/$GIT_EMAIL/g" $HOME/.gitconfig

print_in_yellow ".gitconfig" changed

print_in_green "macOS setup completed!"




echo "macOS setup completed!"
