# Ubuntu AI Engineer Setup

Complete Ubuntu 25.04 development environment setup script for AI engineering with modern CLI tools, editors, and productivity tools.

## One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/dimitritholen/ubuntu-ai-engineer/main/install.sh | bash
```

## What Gets Installed

### 🐚 Shell Environment

- **[Zsh](https://www.zsh.org/)** - Powerful shell with advanced features
- **[Oh My Zsh](https://ohmyz.sh/)** - Framework for managing Zsh configuration
- **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** - Fast and customizable Zsh theme
- **[Starship](https://starship.rs/)** - Cross-shell prompt (alternative to Powerlevel10k)

### 🖥️ Terminal Multiplexers

- **[tmux](https://github.com/tmux/tmux)** - Industry standard terminal multiplexer
- **[zellij](https://zellij.dev/)** - Modern terminal workspace with layouts

### 📦 Version Managers

- **[mise](https://mise.jdx.dev/)** - Universal version manager (replaces asdf, nvm, pyenv, rbenv)
  - Node.js LTS
  - Python 3.12
  - pnpm
- **[uv](https://docs.astral.sh/uv/)** - Ultra-fast Python package manager (replaces pip, poetry, virtualenv)

### 🛠️ Modern CLI Utilities

- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast grep alternative
- **[fd](https://github.com/sharkdp/fd)** - Fast find alternative
- **[bat](https://github.com/sharkdp/bat)** - Cat with syntax highlighting
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder for command-line
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart cd replacement
- **[eza](https://eza.rocks/)** - Modern ls replacement
- **[htop](https://htop.dev/)** - Interactive process viewer
- **[btop](https://github.com/aristocratos/btop)** - Beautiful resource monitor
- **[aria2](https://aria2.github.io/)** - Fast download utility
- **[httpie](https://httpie.io/)** - User-friendly HTTP client
- **[tree](https://gitlab.com/OldManProgrammer/unix-tree)** - Directory tree viewer
- **[ncdu](https://dev.yorhel.nl/ncdu)** - Disk usage analyzer
- **[tldr](https://tldr.sh/)** - Simplified man pages

### 🔧 Git Enhancement Tools

- **[GitHub CLI](https://cli.github.com/)** - Official GitHub command-line tool
- **[git-delta](https://github.com/dandavison/delta)** - Syntax-highlighted git diffs
- **[lazygit](https://github.com/jesseduffield/lazygit)** - Terminal UI for git

### 🐳 Docker & Container Tools

- **[Docker Engine](https://docs.docker.com/engine/)** - Container runtime
- **[Docker Compose](https://docs.docker.com/compose/)** - Multi-container orchestration
- **[lazydocker](https://github.com/jesseduffield/lazydocker)** - Terminal UI for Docker
- **[ctop](https://github.com/bcicen/ctop)** - Container monitoring

### 📝 Code Editors

- **[Visual Studio Code](https://code.visualstudio.com/)** - Popular code editor
- **[Neovim](https://neovim.io/)** - Hyperextensible Vim-based editor
- **[AstroNvim](https://astronvim.com/)** - Feature-rich Neovim configuration
- **[Cursor](https://cursor.sh/)** - AI-powered code editor

### 🤖 AI CLI Tools

- **[Claude CLI](https://www.anthropic.com/)** - Anthropic's Claude AI assistant
- **[Google Gemini CLI](https://www.npmjs.com/package/@google/gemini-cli)** - Google's Gemini AI in your terminal
- **[GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli)** - AI-powered command-line assistant from GitHub
- **[OpenCode CLI](https://opencode.ai/)** - Open-source AI coding agent for terminal
- **[OpenAI Codex CLI](https://www.npmjs.com/package/@openai/codex)** - OpenAI's Codex coding assistant CLI
- **[Goose CLI](https://github.com/block/goose)** - Block/Square's AI developer agent
- **[AIChat](https://github.com/sigoden/aichat)** - Multi-provider AI chat CLI

### ✅ Productivity Tools

- **[TaskWarrior](https://taskwarrior.org/)** - Command-line task management
- **[TimeWarrior](https://timewarrior.net/)** - Time tracking companion to TaskWarrior
- **[glow](https://github.com/charmbracelet/glow)** - Markdown renderer for the terminal
- **[yq](https://github.com/mikefarah/yq)** - YAML/JSON/XML processor

### 🖼️ Desktop Applications

- **[Google Chrome](https://www.google.com/chrome/)** - Web browser
- **[TigerVNC](https://tigervnc.org/)** - VNC server for remote desktop

### 🎨 Fonts

- **[JetBrains Mono Nerd Font](https://www.nerdfonts.com/)** - Programming font with icons
- **[FiraCode Nerd Font](https://www.nerdfonts.com/)** - Programming font with ligatures

### 🦀 Additional Tools

- **[Rust](https://www.rust-lang.org/)** - Systems programming language
- **[direnv](https://direnv.net/)** - Environment variable manager per directory

## System Requirements

- Ubuntu 25.04 "Plucky Puffin" (or compatible versions)
- Sudo privileges
- Internet connection

## Post-Installation

After installation completes, you'll need to:

1. **Log out and log back in** for shell and Docker group changes to take effect

2. **Run configuration wizards:**

   ```bash
   p10k configure  # Configure Powerlevel10k theme
   nvim            # Initialize AstroNvim plugins
   ```

3. **Authenticate CLI tools:**

   ```bash
   gh auth login   # GitHub CLI
   claude          # Claude CLI (requires Anthropic account)
   ```

4. **Configure git identity:**

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

5. **Generate SSH key (if needed):**

   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```

## Manual Installation

If you prefer to review the script before running:

```bash
git clone https://github.com/dimitritholen/ubuntu-ai-engineer.git
cd ubuntu-ai-engineer
chmod +x install.sh
./install.sh
```

## License

MIT License - Feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please open an issue or pull request for any improvements.
