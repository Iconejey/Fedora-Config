#!/bin/bash

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BANNER='\033[30;43m' # Black fg, Yellow bg
NC='\033[0m' # No Color

echo -e "\n${BANNER}                                     ${NC}"
echo -e "${BANNER}  Starting Fedora Init Installation  ${NC}"
echo -e "${BANNER}                                     ${NC}\n"

# 1. Install Fedora system packages via dnf
echo -e "${CYAN}[1/5] Installing packages via DNF...${NC}"
REQUIRED_PKGS=(kitty zsh zsh-autosuggestions zsh-syntax-highlighting nodejs npm git curl)
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! rpm -q "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Missing packages: ${MISSING_PKGS[*]}${NC}"
    echo -e "${YELLOW}Installing...${NC}"
    sudo dnf install -y "${MISSING_PKGS[@]}" --disablerepo="gustavosett-clipboard-manager*"
else
    echo -e "${GREEN}All required system packages are already installed.${NC}"
fi

# 2. Install Oh My Zsh
echo -e "\n${CYAN}[2/5] Installing Oh My Zsh...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Installing Oh My Zsh unattended...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}Oh My Zsh is already installed.${NC}"
fi

# 3. Clone custom Zsh plugins locally (as fallback)
echo -e "\n${CYAN}[3/5] Setting up local Zsh plugins...${NC}"
ZSH_CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$ZSH_CUSTOM_PLUGINS"

if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then
    echo -e "${YELLOW}Cloning zsh-autosuggestions...${NC}"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then
    echo -e "${YELLOW}Cloning zsh-syntax-highlighting...${NC}"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"
fi
echo -e "${GREEN}Zsh plugins setup completed.${NC}"

# 4. Set up configuration symlinks
echo -e "\n${CYAN}[4/5] Setting up configuration symlinks...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper function to create safe links
create_symlink() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
            echo -e "${GREEN}✅ $name config is already linked correctly.${NC}"
            return
        fi
        
        local backup="${dest}.backup-$(date +%s)"
        echo -e "${YELLOW}⚠️ Backing up existing $name config to $backup${NC}"
        mv "$dest" "$backup"
    fi
    
    # If the destination parent directory doesn't exist, create it
    mkdir -p "$(dirname "$dest")"
    
    ln -s "$src" "$dest"
    echo -e "${GREEN}✅ Successfully linked $name config.${NC}"
}

create_symlink "$SCRIPT_DIR/configs/zsh/.zshrc" "$HOME/.zshrc" ".zshrc"
create_symlink "$SCRIPT_DIR/configs/zsh/.zprofile" "$HOME/.zprofile" ".zprofile"

# Link kitty config directory
if [ -d "$HOME/.config/kitty" ] && [ ! -L "$HOME/.config/kitty" ] && [ -z "$(ls -A "$HOME/.config/kitty" 2>/dev/null)" ]; then
    rmdir "$HOME/.config/kitty"
fi
create_symlink "$SCRIPT_DIR/configs/kitty" "$HOME/.config/kitty" "kitty"

# 5. Set default shell to Zsh
echo -e "\n${CYAN}[5/6] Changing default shell to Zsh...${NC}"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_PATH="$(which zsh 2>/dev/null || echo '/usr/bin/zsh')"

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    echo -e "${YELLOW}Changing default shell for $USER to $ZSH_PATH...${NC}"
    chsh -s "$ZSH_PATH"
else
    echo -e "${GREEN}Default shell is already $ZSH_PATH.${NC}"
fi

# 6. Install Microsoft Fonts (Consolas, etc.)
echo -e "\n${CYAN}[6/6] Installing Microsoft Fonts (Consolas, etc.)...${NC}"
if ! rpm -q msttcore-fonts-installer &>/dev/null; then
    echo -e "${YELLOW}Installing cabextract and msttcore-fonts-installer...${NC}"
    sudo dnf install -y cabextract --disablerepo="gustavosett-clipboard-manager*"
    sudo dnf install -y https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
    fc-cache -f
    echo -e "${GREEN}✅ Microsoft fonts installed successfully.${NC}"
else
    echo -e "${GREEN}Microsoft fonts are already installed.${NC}"
fi

echo -e "\n${BANNER}                          ${NC}"
echo -e "${BANNER}  Installation Complete!  ${NC}"
echo -e "${BANNER}                          ${NC}\n"
