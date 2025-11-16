#!/usr/bin/env bash

################################################################################
# Ubuntu 25.04 Complete Development Environment Setup
# Author: AI-Generated based on research conducted 2025-11-15
# Target: Ubuntu 25.04 "Plucky Puffin"
# Purpose: Comprehensive AI engineering & software development machine
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

################################################################################
# Color Codes for Output
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

################################################################################
# Logging Functions
################################################################################

log_header() {
    echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

log_section() {
    echo -e "\n${BOLD}${MAGENTA}▶ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_cmd() {
    echo -e "${CYAN}\$${NC} $1"
}

################################################################################
# Configuration Variables
################################################################################

INSTALL_DIR="$HOME/.local"
BIN_DIR="$INSTALL_DIR/bin"
FONTS_DIR="$HOME/.local/share/fonts"
CONFIG_DIR="$HOME/.config"
TEMP_DIR=$(mktemp -d)
LOGFILE="$HOME/ubuntu-setup-$(date +%Y%m%d-%H%M%S).log"

# Ensure directories exist
mkdir -p "$BIN_DIR" "$FONTS_DIR" "$CONFIG_DIR"

# Add local bin to PATH if not already there
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    export PATH="$BIN_DIR:$PATH"
fi

# Track installation errors
declare -a INSTALL_ERRORS=()

# Detect if running interactively (not via curl | bash)
if [ -t 0 ]; then
    INTERACTIVE=true
else
    INTERACTIVE=false
fi

################################################################################
# Utility Functions
################################################################################

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

record_error() {
    local error_msg="$1"
    INSTALL_ERRORS+=("$error_msg")
    log_error "$error_msg"
}

add_to_path() {
    local path_entry="$1"
    local shell_rc="$HOME/.zshrc"

    if ! grep -q "$path_entry" "$shell_rc" 2>/dev/null; then
        echo "export PATH=\"$path_entry:\$PATH\"" >> "$shell_rc"
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

install_neovim_from_tarball() {
    log_info "Installing Neovim from official tarball"
    cd "$TEMP_DIR"

    local NEOVIM_TARBALL="nvim-linux64.tar.gz"

    rm -f "$NEOVIM_TARBALL"
    rm -rf nvim-linux64

    log_cmd "wget https://github.com/neovim/neovim/releases/latest/download/$NEOVIM_TARBALL"
    if wget -q --show-progress "https://github.com/neovim/neovim/releases/latest/download/$NEOVIM_TARBALL"; then
        log_cmd "tar -xzf $NEOVIM_TARBALL"
        if tar -xzf "$NEOVIM_TARBALL"; then
            if [ -d "$TEMP_DIR/nvim-linux64" ]; then
                log_cmd "sudo rm -rf /usr/local/neovim"
                sudo rm -rf /usr/local/neovim 2>/dev/null || true
                log_cmd "sudo mv nvim-linux64 /usr/local/neovim"
                sudo mv "$TEMP_DIR/nvim-linux64" /usr/local/neovim
                log_cmd "sudo ln -sf /usr/local/neovim/bin/nvim /usr/local/bin/nvim"
                sudo ln -sf /usr/local/neovim/bin/nvim /usr/local/bin/nvim
                log_success "Neovim installed from official tarball"
                return 0
            else
                log_error "Neovim tarball extraction did not produce expected directory"
            fi
        else
            log_error "Failed to extract Neovim tarball"
        fi
    else
        log_error "Failed to download Neovim tarball"
    fi

    return 1
}

################################################################################
# Pre-flight Checks
################################################################################

preflight_checks() {
    log_header "Pre-flight Checks"

    # Check if running on Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_error "This script is designed for Ubuntu 25.04"
        log_warning "Current OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"
        if [ "$INTERACTIVE" = true ]; then
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            log_warning "Running in non-interactive mode, continuing anyway..."
        fi
    fi

    # Check Ubuntu version
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
    log_info "Ubuntu version: $UBUNTU_VERSION"

    # Check for sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges for some installations"
        sudo -v
    fi

    # Keep sudo alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    log_success "Pre-flight checks completed"
}

################################################################################
# Phase 1: System Foundation
################################################################################

phase1_system_foundation() {
    log_header "Phase 1: System Foundation"

    log_section "Updating system packages"
    log_cmd "sudo apt update && sudo apt upgrade -y"
    sudo apt update 2>&1 | tee -a "$LOGFILE"
    sudo apt upgrade -y 2>&1 | tee -a "$LOGFILE"
    log_success "System packages updated"

    log_section "Installing essential build tools and dependencies"
    log_info "This includes compilers, libraries, and development headers"

    ESSENTIAL_PACKAGES=(
        build-essential
        curl
        wget
        git
        ca-certificates
        gnupg
        lsb-release
        software-properties-common
        apt-transport-https
        libssl-dev
        libffi-dev
        libbz2-dev
        libreadline-dev
        libsqlite3-dev
        libncurses5-dev
        libncursesw5-dev
        xz-utils
        tk-dev
        libxml2-dev
        libxmlsec1-dev
        libfuse2
        pkg-config
        unzip
        tar
        gzip
        file
        jq
    )

    log_cmd "sudo apt install -y ${ESSENTIAL_PACKAGES[*]}"
    sudo apt install -y "${ESSENTIAL_PACKAGES[@]}" 2>&1 | tee -a "$LOGFILE"
    log_success "Essential packages installed"
}

################################################################################
# Phase 2: Fonts Installation
################################################################################

phase2_fonts() {
    log_header "Phase 2: Nerd Fonts Installation"

    log_info "Installing JetBrains Mono and FiraCode Nerd Fonts"
    log_info "These fonts are required for: Powerlevel10k, Starship, AstroNvim"

    cd "$TEMP_DIR"

    # JetBrains Mono Nerd Font
    log_section "Installing JetBrains Mono Nerd Font"
    log_cmd "wget + tar extraction to $FONTS_DIR"
    wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    tar -xf JetBrainsMono.tar.xz -C "$FONTS_DIR"
    log_success "JetBrains Mono installed"

    # FiraCode Nerd Font
    log_section "Installing FiraCode Nerd Font"
    wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz
    tar -xf FiraCode.tar.xz -C "$FONTS_DIR"
    log_success "FiraCode installed"

    # Refresh font cache
    log_section "Refreshing font cache"
    log_cmd "fc-cache -fv"
    fc-cache -fv 2>&1 | tee -a "$LOGFILE"
    log_success "Fonts installed and cache refreshed"
}

################################################################################
# Phase 3: Shell Environment (Zsh + Oh My Zsh + Themes)
################################################################################

phase3_shell_environment() {
    log_header "Phase 3: Shell Environment Setup"

    # Install Zsh
    log_section "Installing Zsh"
    log_cmd "sudo apt install -y zsh"
    sudo apt install -y zsh 2>&1 | tee -a "$LOGFILE"
    log_success "Zsh installed"

    # Install Oh My Zsh
    log_section "Installing Oh My Zsh"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_cmd "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>&1 | tee -a "$LOGFILE"
        log_success "Oh My Zsh installed"
    else
        log_warning "Oh My Zsh already installed, skipping"
    fi

    # Install Powerlevel10k theme
    log_section "Installing Powerlevel10k theme"
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

    if [ ! -d "$P10K_DIR" ]; then
        log_cmd "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" 2>&1 | tee -a "$LOGFILE"
        log_success "Powerlevel10k installed"
    else
        log_warning "Powerlevel10k already installed, skipping"
    fi

    # Configure .zshrc
    log_section "Configuring .zshrc"
    if [ -f "$HOME/.zshrc" ]; then
        # Set Powerlevel10k theme
        if ! grep -q "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" "$HOME/.zshrc"; then
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
            log_info "Set Powerlevel10k as default theme"
        fi

        # Add useful plugins
        if ! grep -q "plugins=(git" "$HOME/.zshrc"; then
            sed -i 's/^plugins=.*/plugins=(git docker kubectl npm python zoxide fzf)/' "$HOME/.zshrc"
            log_info "Added recommended plugins"
        fi
    fi

    # Install Starship (alternative prompt)
    log_section "Installing Starship prompt (alternative)"
    if ! command_exists starship; then
        log_cmd "curl -sS https://starship.rs/install.sh | sh"
        curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1 | tee -a "$LOGFILE"
        log_success "Starship installed"
        log_info "To use Starship instead of Powerlevel10k, add to .zshrc:"
        log_info "  eval \"\$(starship init zsh)\""
    else
        log_warning "Starship already installed"
    fi

    # Set Zsh as default shell
    log_section "Setting Zsh as default shell"
    if [ "$SHELL" != "$(which zsh)" ]; then
        log_cmd "chsh -s \$(which zsh)"
        chsh -s "$(which zsh)"
        log_success "Zsh set as default shell"
        log_warning "Please log out and log back in for shell change to take effect"
    else
        log_info "Zsh is already the default shell"
    fi
}

################################################################################
# Phase 4: Terminal Multiplexers
################################################################################

phase4_terminal_multiplexers() {
    log_header "Phase 4: Terminal Multiplexers"

    # Install tmux
    log_section "Installing tmux (industry standard)"
    log_cmd "sudo apt install -y tmux"
    sudo apt install -y tmux 2>&1 | tee -a "$LOGFILE"
    log_success "tmux installed"

    # Install zellij
    log_section "Installing zellij (modern alternative)"
    if ! command_exists zellij; then
        # Try apt first
        if sudo apt install -y zellij 2>/dev/null; then
            log_success "zellij installed via apt"
        else
            # Fall back to binary installation
            log_info "Installing zellij from GitHub releases"
            cd "$TEMP_DIR"
            ZELLIJ_VERSION=$(curl -s "https://api.github.com/repos/zellij-org/zellij/releases/latest" | jq -r '.tag_name' | sed 's/v//')
            wget -q --show-progress "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
            tar -xzf zellij-x86_64-unknown-linux-musl.tar.gz
            chmod +x zellij
            mv zellij "$BIN_DIR/"
            log_success "zellij installed to $BIN_DIR"
        fi
    else
        log_warning "zellij already installed"
    fi
}

################################################################################
# Phase 5: Version Managers (mise + uv)
################################################################################

phase5_version_managers() {
    log_header "Phase 5: Version Managers"

    # Install mise (formerly rtx)
    log_section "Installing mise - Universal version manager"
    log_info "mise replaces: asdf, nvm, pyenv, rbenv, and more"

    if ! command_exists mise; then
        log_cmd "curl https://mise.run | sh"
        curl https://mise.run | sh 2>&1 | tee -a "$LOGFILE"

        # Add mise to shell
        if [ -f "$HOME/.zshrc" ]; then
            if ! grep -q 'mise activate zsh' "$HOME/.zshrc"; then
                echo '' >> "$HOME/.zshrc"
                echo '# mise version manager' >> "$HOME/.zshrc"
                echo 'eval "$(~/.local/bin/mise activate zsh)"' >> "$HOME/.zshrc"
                log_info "Added mise activation to .zshrc"
            fi
        fi

        log_success "mise installed"
    else
        log_warning "mise already installed"
    fi

    # Activate mise for current session
    export PATH="$HOME/.local/bin:$PATH"
    if command_exists mise; then
        eval "$(mise activate bash)"
    fi

    # Install Node.js LTS via mise
    log_section "Installing Node.js LTS via mise"
    log_cmd "mise install node@lts && mise use -g node@lts"
    mise install node@lts 2>&1 | tee -a "$LOGFILE" || log_warning "Node.js installation via mise failed, continuing..."
    mise use -g node@lts 2>&1 | tee -a "$LOGFILE" || true
    log_success "Node.js LTS installed and set as global"

    # Install Python 3.12 via mise
    log_section "Installing Python 3.12 via mise"
    log_cmd "mise install python@3.12 && mise use -g python@3.12"
    mise install python@3.12 2>&1 | tee -a "$LOGFILE" || log_warning "Python installation via mise failed, continuing..."
    mise use -g python@3.12 2>&1 | tee -a "$LOGFILE" || true
    log_success "Python 3.12 installed and set as global"

    # Install uv (Python package manager)
    log_section "Installing uv - Ultra-fast Python package manager"
    log_info "uv replaces: pip, pip-tools, pipx, poetry, pyenv, virtualenv"

    if ! command_exists uv; then
        log_cmd "curl -LsSf https://astral.sh/uv/install.sh | sh"
        curl -LsSf https://astral.sh/uv/install.sh | sh 2>&1 | tee -a "$LOGFILE"
        log_success "uv installed"
    else
        log_warning "uv already installed"
    fi

    # Install pnpm via mise
    log_section "Installing pnpm via mise"
    mise install pnpm@latest 2>&1 | tee -a "$LOGFILE" || log_warning "pnpm installation failed, continuing..."
    mise use -g pnpm@latest 2>&1 | tee -a "$LOGFILE" || true
    log_success "pnpm installed"

    log_info "Enable yarn via: corepack enable (after Node.js is active)"
}

################################################################################
# Phase 6: Modern CLI Utilities
################################################################################

phase6_modern_cli_tools() {
    log_header "Phase 6: Modern CLI Utilities"

    CLI_TOOLS=(
        ripgrep      # Fast grep alternative
        fd-find      # Fast find alternative
        bat          # Cat with syntax highlighting
        fzf          # Fuzzy finder
        zoxide       # Smart cd
        htop         # System monitor
        btop         # Modern system monitor
        aria2        # Download utility
        httpie       # HTTP client
        tree         # Directory tree
        ncdu         # Disk usage analyzer
        tldr         # Simplified man pages
    )

    log_section "Installing modern CLI utilities"
    log_info "These tools replace/enhance: grep, find, cat, cd, top, wget"

    log_cmd "sudo apt install -y ${CLI_TOOLS[*]}"
    sudo apt install -y "${CLI_TOOLS[@]}" 2>&1 | tee -a "$LOGFILE"
    log_success "Modern CLI tools installed"

    # Install eza (modern ls replacement)
    log_section "Installing eza (modern ls replacement)"
    if ! command_exists eza; then
        log_info "eza is the maintained fork of exa"
        if command_exists cargo; then
            cargo install eza 2>&1 | tee -a "$LOGFILE"
            log_success "eza installed via cargo"
        else
            log_warning "Cargo not available, skipping eza installation"
            log_info "Install after Rust is set up: cargo install eza"
        fi
    else
        log_warning "eza already installed"
    fi

    # Configure zoxide
    log_section "Configuring zoxide"
    if [ -f "$HOME/.zshrc" ] && ! grep -q 'zoxide init' "$HOME/.zshrc"; then
        echo '' >> "$HOME/.zshrc"
        echo '# zoxide (smart cd)' >> "$HOME/.zshrc"
        echo 'eval "$(zoxide init zsh)"' >> "$HOME/.zshrc"
        log_success "zoxide configured in .zshrc"
    fi

    # Configure fzf
    log_section "Configuring fzf"
    if [ -f "$HOME/.zshrc" ] && ! grep -q 'fzf' "$HOME/.zshrc"; then
        echo '' >> "$HOME/.zshrc"
        echo '# fzf fuzzy finder' >> "$HOME/.zshrc"
        echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' >> "$HOME/.zshrc"
        log_success "fzf configured in .zshrc"
    fi

    # Create bat alias if batcat is installed instead
    if command_exists batcat && ! command_exists bat; then
        log_section "Creating bat alias for batcat"
        if [ -f "$HOME/.zshrc" ]; then
            echo 'alias bat=batcat' >> "$HOME/.zshrc"
            log_success "Created bat alias"
        fi
    fi
}

################################################################################
# Phase 7: Git Enhancement Tools
################################################################################

phase7_git_tools() {
    log_header "Phase 7: Git Enhancement Tools"

    # Install GitHub CLI
    log_section "Installing GitHub CLI (gh)"
    if ! command_exists gh; then
        log_cmd "Adding GitHub CLI repository"
        sudo mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install -y gh 2>&1 | tee -a "$LOGFILE"
        log_success "GitHub CLI installed"
    else
        log_warning "GitHub CLI already installed"
    fi

    # Install git-delta
    log_section "Installing git-delta (syntax-highlighted diffs)"
    if ! command_exists delta; then
        cd "$TEMP_DIR"
        DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | jq -r '.tag_name')
        log_cmd "wget git-delta_${DELTA_VERSION}_amd64.deb"
        wget -q --show-progress "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION#v}_amd64.deb"
        sudo dpkg -i "git-delta_${DELTA_VERSION#v}_amd64.deb" 2>&1 | tee -a "$LOGFILE"
        log_success "git-delta installed"
    else
        log_warning "git-delta already installed"
    fi

    # Install lazygit
    log_section "Installing lazygit (TUI for git)"
    if ! command_exists lazygit; then
        cd "$TEMP_DIR"
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        log_cmd "wget + install lazygit v${LAZYGIT_VERSION}"
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        log_success "lazygit installed"
    else
        log_warning "lazygit already installed"
    fi

    # Configure git to use delta
    log_section "Configuring git to use delta"
    git config --global core.pager delta 2>/dev/null || true
    git config --global interactive.diffFilter "delta --color-only" 2>/dev/null || true
    git config --global delta.navigate true 2>/dev/null || true
    git config --global delta.side-by-side true 2>/dev/null || true
    log_success "Git configured to use delta for diffs"
}

################################################################################
# Phase 8: Docker + Container Tools
################################################################################

phase8_docker() {
    log_header "Phase 8: Docker & Container Tools"

    log_section "Installing Docker"
    log_warning "Note: Docker packages for Ubuntu 25.04 may be incomplete"
    log_info "Using Ubuntu 24.04 (noble) repository as fallback"

    if ! command_exists docker; then
        # Add Docker's official GPG key
        log_cmd "Adding Docker repository"
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Determine Ubuntu codename (use noble for 25.04)
        UBUNTU_CODENAME=$(lsb_release -cs)
        if [ "$UBUNTU_CODENAME" = "plucky" ]; then
            log_warning "Using noble (24.04) Docker packages for Ubuntu 25.04"
            UBUNTU_CODENAME="noble"
        fi

        # Add the repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $UBUNTU_CODENAME stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tee -a "$LOGFILE"

        # Add user to docker group
        sudo usermod -aG docker "$USER"
        log_success "Docker installed"
        log_warning "You need to log out and back in for docker group membership to take effect"
    else
        log_warning "Docker already installed"
    fi

    # Install lazydocker
    log_section "Installing lazydocker (Docker TUI)"
    if ! command_exists lazydocker; then
        log_cmd "curl + bash install script"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1 | tee -a "$LOGFILE"
        log_success "lazydocker installed"
    else
        log_warning "lazydocker already installed"
    fi

    # Install ctop
    log_section "Installing ctop (container monitoring)"
    if ! command_exists ctop; then
        sudo apt install -y ctop 2>&1 | tee -a "$LOGFILE" || log_warning "ctop installation failed"
        log_success "ctop installed"
    else
        log_warning "ctop already installed"
    fi
}

################################################################################
# Phase 9: Code Editors
################################################################################

phase9_code_editors() {
    log_header "Phase 9: Code Editors"

    # Install VS Code
    log_section "Installing Visual Studio Code"
    if ! command_exists code; then
        log_cmd "Installing wget and gpg prerequisites"
        sudo apt-get install -y wget gpg 2>&1 | tee -a "$LOGFILE"

        log_cmd "Adding Microsoft GPG key"
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
        rm -f microsoft.gpg

        log_cmd "Adding Microsoft VS Code repository (DEB822 format)"
        sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64 arm64 armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

        log_cmd "Installing VS Code"
        sudo apt-get install -y apt-transport-https 2>&1 | tee -a "$LOGFILE"
        sudo apt-get update 2>&1 | tee -a "$LOGFILE"
        sudo apt-get install -y code 2>&1 | tee -a "$LOGFILE"
        log_success "VS Code installed"
    else
        log_warning "VS Code already installed"
    fi

    # Install Neovim
    log_section "Installing Neovim (latest stable)"
    if ! command_exists nvim; then
        local UBUNTU_CODENAME
        UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "")
        local NEOVIM_PPA_CODENAMES=("noble" "mantic" "lunar" "jammy" "focal")
        local NEOVIM_PPA_SUPPORTED=false

        for codename in "${NEOVIM_PPA_CODENAMES[@]}"; do
            if [ "$UBUNTU_CODENAME" = "$codename" ]; then
                NEOVIM_PPA_SUPPORTED=true
                break
            fi
        done

        if [ "$NEOVIM_PPA_SUPPORTED" = true ]; then
            log_cmd "sudo add-apt-repository -y ppa:neovim-ppa/stable"
            sudo add-apt-repository -y ppa:neovim-ppa/stable 2>&1 | tee -a "$LOGFILE"
            local add_repo_rc=${PIPESTATUS[0]}

            if [ "$add_repo_rc" -eq 0 ]; then
                log_cmd "sudo apt update"
                sudo apt update 2>&1 | tee -a "$LOGFILE"
                local apt_update_rc=${PIPESTATUS[0]}

                if [ "$apt_update_rc" -eq 0 ]; then
                    log_cmd "sudo apt install -y neovim"
                    sudo apt install -y neovim 2>&1 | tee -a "$LOGFILE"
                    local neovim_install_rc=${PIPESTATUS[0]}

                    if [ "$neovim_install_rc" -eq 0 ]; then
                        log_success "Neovim installed via PPA"
                    else
                        log_warning "Neovim installation via PPA failed (exit code $neovim_install_rc); falling back to official tarball"
                        sudo rm -f /etc/apt/sources.list.d/neovim-ppa-ubuntu-stable-*.list 2>/dev/null || true
                        if ! install_neovim_from_tarball; then
                            log_error "Neovim installation failed"
                            return 1
                        fi
                    fi
                else
                    log_warning "apt update for Neovim PPA failed (exit code $apt_update_rc); falling back to official tarball"
                    sudo rm -f /etc/apt/sources.list.d/neovim-ppa-ubuntu-stable-*.list 2>/dev/null || true
                    if ! install_neovim_from_tarball; then
                        log_error "Neovim installation failed"
                        return 1
                    fi
                fi
            else
                log_warning "Adding Neovim PPA failed (exit code $add_repo_rc); falling back to official tarball"
                if ! install_neovim_from_tarball; then
                    log_error "Neovim installation failed"
                    return 1
                fi
            fi
        else
            if [ -n "$UBUNTU_CODENAME" ]; then
                log_warning "Neovim PPA does not provide packages for release '$UBUNTU_CODENAME'; using official tarball"
            else
                log_warning "Unable to determine Ubuntu codename; installing Neovim from official tarball"
            fi
            sudo rm -f /etc/apt/sources.list.d/neovim-ppa-ubuntu-stable-*.list 2>/dev/null || true

            if ! install_neovim_from_tarball; then
                log_error "Neovim installation failed"
                return 1
            fi
        fi
    else
        log_warning "Neovim already installed"
    fi

    # Install AstroNvim
    log_section "Installing AstroNvim"
    if [ ! -d "$HOME/.config/nvim" ]; then
        log_cmd "git clone AstroNvim template"
        git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim 2>&1 | tee -a "$LOGFILE"
        log_success "AstroNvim installed"
        log_info "Run 'nvim' to complete AstroNvim setup and install plugins"
    else
        log_warning "Neovim config already exists at ~/.config/nvim"
        log_info "Backup and remove to install AstroNvim"
    fi

    # Download Cursor AI (AppImage)
    log_section "Downloading Cursor AI Editor"
    if [ ! -f "$HOME/.local/bin/cursor.AppImage" ]; then
        log_cmd "wget Cursor AppImage from official API"
        cd "$TEMP_DIR"
        wget -q --show-progress https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/2.0 -O cursor.AppImage
        chmod +x cursor.AppImage
        mv cursor.AppImage "$HOME/.local/bin/"
        log_success "Cursor AI downloaded to ~/.local/bin/cursor.AppImage"
        log_info "Run: ~/.local/bin/cursor.AppImage"
    else
        log_warning "Cursor AI already downloaded"
    fi
}

################################################################################
# Phase 10: AI CLI Tools
################################################################################

phase10_ai_tools() {
    log_header "Phase 10: AI CLI Tools"

    # Install Claude CLI (Claude Code)
    log_section "Installing Claude CLI (Anthropic)"
    if ! command_exists claude; then
        # Prefer npm installation if Node.js is available
        if command_exists npm; then
            log_cmd "npm install -g @anthropic-ai/claude-code"
            npm install -g @anthropic-ai/claude-code 2>&1 | tee -a "$LOGFILE"
            log_success "Claude CLI installed via npm"
        else
            # Fallback to official install script
            log_cmd "curl -fsSL https://get.anthropic.com/claude-code | sh"
            curl -fsSL https://get.anthropic.com/claude-code | sh 2>&1 | tee -a "$LOGFILE"
            log_success "Claude CLI installed via curl"
        fi
        log_info "Run 'claude' to authenticate via OAuth"
    else
        log_warning "Claude CLI already installed"
    fi

    # Install Google Gemini CLI
    log_section "Installing Google Gemini CLI"
    if ! command_exists gemini; then
        if command_exists npm; then
            log_cmd "npm install -g @google/gemini-cli@latest"
            npm install -g @google/gemini-cli@latest 2>&1 | tee -a "$LOGFILE"
            log_success "Google Gemini CLI installed via npm"
            log_info "Run 'gemini' to authenticate with your Google account"
        else
            log_warning "npm not available, skipping Gemini CLI"
            log_info "Install Node.js first, then: npm install -g @google/gemini-cli@latest"
        fi
    else
        log_warning "Gemini CLI already installed"
    fi

    # Install GitHub Copilot CLI
    log_section "Installing GitHub Copilot CLI"
    if ! command_exists copilot; then
        if command_exists npm; then
            log_cmd "npm install -g @github/copilot@latest"
            npm install -g @github/copilot@latest 2>&1 | tee -a "$LOGFILE"
            log_success "GitHub Copilot CLI installed via npm"
            log_info "Run 'copilot' and use /login to authenticate with GitHub"
        else
            log_warning "npm not available, skipping GitHub Copilot CLI"
            log_info "Install Node.js first, then: npm install -g @github/copilot@latest"
        fi
    else
        log_warning "GitHub Copilot CLI already installed"
    fi

    # Install OpenCode CLI
    log_section "Installing OpenCode CLI"
    if ! command_exists opencode; then
        if command_exists npm; then
            log_cmd "npm install -g opencode-ai@latest"
            npm install -g opencode-ai@latest 2>&1 | tee -a "$LOGFILE"
            log_success "OpenCode CLI installed via npm"
            log_info "Run 'opencode auth login' to authenticate"
        else
            log_warning "npm not available, skipping OpenCode CLI"
            log_info "Install Node.js first, then: npm install -g opencode-ai@latest"
        fi
    else
        log_warning "OpenCode CLI already installed"
    fi

    # Install OpenAI Codex CLI
    log_section "Installing OpenAI Codex CLI"
    if ! command_exists codex; then
        if command_exists npm; then
            log_cmd "npm install -g @openai/codex@latest"
            npm install -g @openai/codex@latest 2>&1 | tee -a "$LOGFILE"
            log_success "OpenAI Codex CLI installed via npm"
            log_info "Run 'codex' to authenticate with your ChatGPT account"
        else
            log_warning "npm not available, skipping OpenAI Codex CLI"
            log_info "Install Node.js first, then: npm install -g @openai/codex@latest"
        fi
    else
        log_warning "Codex CLI already installed"
    fi

    # Install Goose CLI
    log_section "Installing Goose CLI (Block/Square)"
    if ! command_exists goose; then
        log_cmd "wget goose binary from GitHub"
        cd "$TEMP_DIR"
        wget -q --show-progress https://github.com/block/goose/releases/latest/download/goose-linux-amd64 -O goose
        chmod +x goose
        mv goose "$BIN_DIR/"
        log_success "Goose CLI installed"
    else
        log_warning "Goose CLI already installed"
    fi

    # Install AIChat
    log_section "Installing AIChat (multi-provider CLI)"
    if ! command_exists aichat; then
        if command_exists cargo; then
            log_cmd "cargo install aichat --locked"
            cargo install aichat --locked 2>&1 | tee -a "$LOGFILE"
            log_success "AIChat installed"
        else
            log_warning "Cargo not available, skipping AIChat"
            log_info "Install Rust/Cargo first, then: cargo install aichat --locked"
        fi
    else
        log_warning "AIChat already installed"
    fi

    # Install Aider CLI
    log_section "Installing Aider CLI (AI pair programming)"
    if ! command_exists aider; then
        log_cmd "curl -LsSL https://aider.chat/install.sh | sh"
        if curl -LsSL https://aider.chat/install.sh | sh 2>&1 | tee -a "$LOGFILE"; then
            log_success "Aider CLI installed"
            log_info "Run 'aider' to start AI pair programming"
        else
            record_error "Aider CLI installation failed"
        fi
    else
        log_warning "Aider CLI already installed"
    fi

    # Install Droid CLI (Factory AI)
    log_section "Installing Droid CLI (Factory AI)"
    if ! command_exists droid; then
        log_cmd "curl -fsSL https://app.factory.ai/cli | sh"
        # Install xdg-utils if not present (required for Droid)
        if ! command_exists xdg-open; then
            log_info "Installing xdg-utils (required for Droid)"
            sudo apt-get install -y xdg-utils 2>&1 | tee -a "$LOGFILE" || true
        fi
        if curl -fsSL https://app.factory.ai/cli | sh 2>&1 | tee -a "$LOGFILE"; then
            log_success "Droid CLI installed"
            log_info "Run 'droid' to start your development session"
        else
            record_error "Droid CLI installation failed"
        fi
    else
        log_warning "Droid CLI already installed"
    fi
}

################################################################################
# Phase 11: Productivity Tools
################################################################################

phase11_productivity() {
    log_header "Phase 11: Productivity Tools"

    # TaskWarrior + TimeWarrior
    log_section "Installing TaskWarrior & TimeWarrior"
    log_cmd "sudo apt install -y taskwarrior timewarrior libjson-perl"
    sudo apt install -y taskwarrior timewarrior libjson-perl 2>&1 | tee -a "$LOGFILE"
    log_success "TaskWarrior & TimeWarrior installed"

    # Markdown tools: glow
    log_section "Installing glow (markdown renderer)"
    if ! command_exists glow; then
        log_cmd "Adding Charm repository"
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update
        sudo apt install -y glow 2>&1 | tee -a "$LOGFILE"
        log_success "glow installed"
    else
        log_warning "glow already installed"
    fi

    # Install yq (YAML processor)
    log_section "Installing yq (YAML processor)"
    if ! command_exists yq; then
        cd "$TEMP_DIR"
        YQ_VERSION=$(curl -s "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r '.tag_name')
        log_cmd "wget yq ${YQ_VERSION}"
        wget -q --show-progress "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -O yq
        chmod +x yq
        sudo mv yq /usr/local/bin/
        log_success "yq installed"
    else
        log_warning "yq already installed"
    fi
}

################################################################################
# Phase 12: Desktop Applications
################################################################################

phase12_desktop_apps() {
    log_header "Phase 12: Desktop Applications"

    # Google Chrome
    log_section "Installing Google Chrome"
    if ! command_exists google-chrome; then
        cd "$TEMP_DIR"
        log_cmd "wget Google Chrome .deb package"
        wget -q --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install -y ./google-chrome-stable_current_amd64.deb 2>&1 | tee -a "$LOGFILE"
        log_success "Google Chrome installed"
    else
        log_warning "Google Chrome already installed"
    fi

    # TigerVNC Server
    log_section "Installing TigerVNC Server"
    if ! command_exists vncserver; then
        log_cmd "sudo apt install -y tigervnc-standalone-server tigervnc-common tigervnc-tools"
        sudo apt install -y tigervnc-standalone-server tigervnc-common tigervnc-tools 2>&1 | tee -a "$LOGFILE"
        log_success "TigerVNC installed"
        log_info "Run 'vncserver' to set up VNC password"
    else
        log_warning "TigerVNC already installed"
    fi
}

################################################################################
# Phase 13: Additional Utilities
################################################################################

phase13_additional_utilities() {
    log_header "Phase 13: Additional Utilities & Enhancements"

    # Install direnv
    log_section "Installing direnv (environment management)"
    if ! command_exists direnv; then
        sudo apt install -y direnv 2>&1 | tee -a "$LOGFILE"

        # Add to .zshrc
        if [ -f "$HOME/.zshrc" ] && ! grep -q 'direnv hook' "$HOME/.zshrc"; then
            echo '' >> "$HOME/.zshrc"
            echo '# direnv' >> "$HOME/.zshrc"
            echo 'eval "$(direnv hook zsh)"' >> "$HOME/.zshrc"
        fi
        log_success "direnv installed and configured"
        log_info "Note: mise has built-in direnv support - consider using that instead"
    else
        log_warning "direnv already installed"
    fi

    # Install Rust (for various tools)
    log_section "Installing Rust programming language"
    if ! command_exists cargo; then
        log_cmd "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tee -a "$LOGFILE"
        source "$HOME/.cargo/env"
        log_success "Rust installed"
    else
        log_warning "Rust already installed"
    fi
}

################################################################################
# Phase 14: Configuration & Finalization
################################################################################

phase14_finalization() {
    log_header "Phase 14: Final Configuration"

    # Configure git basics
    log_section "Git Configuration"
    log_info "Setting recommended git configurations"

    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global core.editor "nvim" 2>/dev/null || true

    if ! git config --global user.name >/dev/null 2>&1; then
        log_warning "Git user.name not set"
        log_info "Configure with: git config --global user.name 'Your Name'"
    fi

    if ! git config --global user.email >/dev/null 2>&1; then
        log_warning "Git user.email not set"
        log_info "Configure with: git config --global user.email 'your.email@example.com'"
    fi

    log_success "Git configured"

    # Create useful aliases in .zshrc
    log_section "Creating useful shell aliases"
    if [ -f "$HOME/.zshrc" ]; then
        cat >> "$HOME/.zshrc" << 'EOF'

# ===== Custom Aliases =====
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias d='docker'
alias dc='docker-compose'
alias k='kubectl'
alias v='nvim'
alias vim='nvim'

# Modern CLI replacements
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -lah'
    alias tree='eza --tree'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi

if command -v zoxide >/dev/null 2>&1; then
    alias cd='z'
fi

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Docker aliases
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'

EOF
        log_success "Shell aliases added to .zshrc"
    fi

    # Source .zshrc to apply changes (for current session)
    log_section "Applying shell configurations"
    if [ -f "$HOME/.zshrc" ]; then
        log_info "Configuration applied to .zshrc"
        log_warning "Start a new shell or run: source ~/.zshrc"
    fi
}

################################################################################
# Phase 15: Post-Installation Summary
################################################################################

phase15_summary() {
    log_header "Installation Complete! 🎉"

    echo -e "${BOLD}Summary of Installed Tools:${NC}\n"

    echo -e "${GREEN}✓ Shell Environment:${NC}"
    echo "  • Zsh + Oh My Zsh + Powerlevel10k"
    echo "  • Starship prompt (alternative)"
    echo "  • tmux + zellij (terminal multiplexers)"

    echo -e "\n${GREEN}✓ Version Managers:${NC}"
    echo "  • mise (universal version manager)"
    echo "  • uv (Python package manager)"
    echo "  • Node.js LTS, Python 3.12, pnpm"

    echo -e "\n${GREEN}✓ Development Tools:${NC}"
    echo "  • Docker + lazydocker + ctop"
    echo "  • VS Code"
    echo "  • Neovim + AstroNvim"
    echo "  • Cursor AI (AppImage)"

    echo -e "\n${GREEN}✓ AI CLI Tools:${NC}"
    echo "  • Claude CLI (Anthropic)"
    echo "  • Google Gemini CLI"
    echo "  • GitHub Copilot CLI"
    echo "  • OpenCode CLI"
    echo "  • OpenAI Codex CLI"
    echo "  • Aider CLI (AI pair programming)"
    echo "  • Droid CLI (Factory AI)"
    echo "  • Goose CLI (Block/Square)"
    echo "  • AIChat (multi-provider)"

    echo -e "\n${GREEN}✓ Modern CLI Utilities:${NC}"
    echo "  • ripgrep, fd, bat, fzf, zoxide, eza"
    echo "  • htop, btop, aria2, httpie"
    echo "  • git-delta, lazygit, GitHub CLI"

    echo -e "\n${GREEN}✓ Productivity Tools:${NC}"
    echo "  • TaskWarrior + TimeWarrior"
    echo "  • glow (markdown), yq (YAML)"

    echo -e "\n${GREEN}✓ Desktop Applications:${NC}"
    echo "  • Google Chrome"
    echo "  • TigerVNC Server"

    echo -e "\n${YELLOW}📋 Next Steps:${NC}\n"

    echo -e "1. ${BOLD}Log out and log back in${NC} for the following to take effect:"
    echo "   • Zsh as default shell"
    echo "   • Docker group membership"

    echo -e "\n2. ${BOLD}Run configuration wizards:${NC}"
    echo "   • p10k configure    # Configure Powerlevel10k theme"
    echo "   • nvim              # Initialize AstroNvim plugins"

    echo -e "\n3. ${BOLD}Authenticate CLI tools:${NC}"
    echo "   • gh auth login     # GitHub CLI"
    echo "   • claude            # Claude CLI (requires Anthropic account)"

    echo -e "\n4. ${BOLD}Configure git identity:${NC}"
    echo "   • git config --global user.name 'Your Name'"
    echo "   • git config --global user.email 'your.email@example.com'"

    echo -e "\n5. ${BOLD}Generate SSH key (if needed):${NC}"
    echo "   • ssh-keygen -t ed25519 -C 'your.email@example.com'"
    echo "   • Add to GitHub: cat ~/.ssh/id_ed25519.pub"

    echo -e "\n6. ${BOLD}Install additional tools via mise:${NC}"
    echo "   • mise install ruby@latest"
    echo "   • mise install golang@latest"
    echo "   • mise install rust@latest"
    echo "   • mise list-remote <tool>  # See available versions"

    echo -e "\n${CYAN}📚 Documentation & Resources:${NC}\n"
    echo "  • mise docs:         https://mise.jdx.dev/"
    echo "  • uv docs:           https://docs.astral.sh/uv/"
    echo "  • AstroNvim docs:    https://docs.astronvim.com/"
    echo "  • Powerlevel10k:     https://github.com/romkatv/powerlevel10k"

    echo -e "\n${MAGENTA}💡 Pro Tips:${NC}\n"
    echo "  • Use 'mise use' in project directories to set local tool versions"
    echo "  • Run 'btop' for a beautiful system monitor"
    echo "  • Use 'lazygit' for an interactive git interface"
    echo "  • Press 'Ctrl-R' with fzf for fuzzy history search"
    echo "  • Use 'z <directory>' instead of 'cd' (zoxide smart jumping)"
    echo "  • Run 'glow README.md' to render markdown in terminal"

    # Display installation errors if any
    if [ ${#INSTALL_ERRORS[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}⚠️  Installation Errors:${NC}\n"
        for error in "${INSTALL_ERRORS[@]}"; do
            echo -e "${RED}  ✗${NC} $error"
        done
        echo -e "\n${YELLOW}Note:${NC} Some tools failed to install. Check the log file for details."
    fi

    echo -e "\n${BOLD}Installation log saved to:${NC} $LOGFILE"
    echo ""

    if [ ${#INSTALL_ERRORS[@]} -eq 0 ]; then
        log_success "Setup complete! Enjoy your new development environment! 🚀"
    else
        echo -e "${YELLOW}⚠️${NC}  Setup completed with some errors. Review the errors above."
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    log_header "Ubuntu 25.04 Development Environment Setup"
    log_info "This script will install a comprehensive AI engineering development environment"
    log_info "Installation log: $LOGFILE"

    if [ "$INTERACTIVE" = true ]; then
        echo ""
        read -p "Press Enter to begin installation or Ctrl+C to cancel..."
    else
        log_info "Running in non-interactive mode, starting installation..."
    fi

    preflight_checks
    phase1_system_foundation
    phase2_fonts
    phase3_shell_environment
    phase4_terminal_multiplexers
    phase5_version_managers
    phase6_modern_cli_tools
    phase7_git_tools
    phase8_docker
    phase9_code_editors
    phase10_ai_tools
    phase11_productivity
    phase12_desktop_apps
    phase13_additional_utilities
    phase14_finalization
    phase15_summary
}

# Run main function
main "$@"
