#! /bin/bash

# Install oh-my-zsh
echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "Done"

# Install oh-my-zsh plugins
echo ""
echo "Installing oh-my-zsh plugins..."
# plugins=(git nvm fzf-tab zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting)

# fzf-tab
echo "Installing fzf-tab..."
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
echo "Done"

# zsh-autosuggestions
echo "Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
echo "Done"

# zsh-syntax-highlighting
echo "Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo "Done"

# fast-syntax-highlighting
echo "Installing fast-syntax-highlighting..."
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
echo "Done"

# Update oh-my-zsh plugins config
# replace plugins=(.*) with plugins=(git nvm fzf-tab zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting)
echo "Updating oh-my-zsh plugins config..."
sed -i '' 's/^plugins=(.*)/plugins=(git nvm fzf-tab zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting)/' ~/.zshrc
echo "Done"

echo ""
echo "Finished ✅"
