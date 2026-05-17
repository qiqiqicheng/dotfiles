#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

ZSH_VERSION="5.9"
ZSH_SRC_URL="https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VERSION}/zsh-${ZSH_VERSION}.tar.xz/download"
LOCAL_DIR="$HOME/.local"
ZSH_BIN="$LOCAL_DIR/bin/zsh"

echo "========================================"
echo " Step 1: Checking/Installing Zsh"
echo "========================================"

if command -v zsh >/dev/null 2>&1; then
    echo "-> Zsh is already installed system-wide."
    ZSH_BIN=$(command -v zsh)
elif [ -x "$ZSH_BIN" ]; then
    echo "-> Zsh is already installed locally in $LOCAL_DIR."
else
    echo "-> Zsh not found. Downloading and compiling from source..."
    mkdir -p "$LOCAL_DIR"
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    echo "-> Downloading Zsh ${ZSH_VERSION}..."
    curl -L "$ZSH_SRC_URL" -o zsh.tar.xz
    tar -xf zsh.tar.xz
    cd "zsh-${ZSH_VERSION}"
    
    echo "-> Compiling Zsh (this might take a minute)..."
    ./configure --prefix="$LOCAL_DIR"
    make -j$(nproc)
    make install
    
    cd ~
    rm -rf "$TEMP_DIR"
    echo "-> Zsh compiled and installed to $LOCAL_DIR/bin/zsh."
fi

# Ensure local bin is temporarily in PATH for the rest of the script
export PATH="$LOCAL_DIR/bin:$PATH"

echo ""
echo "========================================"
echo " Step 2: Installing Oh-My-Zsh"
echo "========================================"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "-> Installing Oh-My-Zsh (unattended)..."
    # CHSH=no prevents chsh (requires root/password)
    # RUNZSH=no prevents spawning a shell and pausing the script
    env CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "-> Oh-My-Zsh is already installed."
fi

echo ""
echo "========================================"
echo " Step 3: Installing Essential Plugins"
echo "========================================"

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# 1. zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "-> Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# 2. zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "-> Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

echo ""
echo "========================================"
echo " Step 4: Configuring .zshrc"
echo "========================================"

# Update plugins list in .zshrc
sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
echo "-> Enabled plugins: git, zsh-autosuggestions, zsh-syntax-highlighting."

# Ensure local bin is exported in .zshrc so local tools work
if ! grep -q "export PATH=\"$LOCAL_DIR/bin:\$PATH\"" "$HOME/.zshrc"; then
    echo "export PATH=\"$LOCAL_DIR/bin:\$PATH\"" >> "$HOME/.zshrc"
fi

echo ""
echo "========================================"
echo " Step 5: Bypassing chsh (Auto-start Zsh)"
echo "========================================"

BASHRC="$HOME/.bashrc"

AUTOSTART_SNIPPET="
# === Auto-launch Zsh for interactive shells ===
if [[ \$- == *i* ]]; then
    export PATH=\"$LOCAL_DIR/bin:\$PATH\"
    if [ -x \"$ZSH_BIN\" ]; then
        export SHELL=\"$ZSH_BIN\"
        exec \"$ZSH_BIN\" -l
    elif command -v zsh >/dev/null 2>&1; then
        export SHELL=\"\$(command -v zsh)\"
        exec \"\$(command -v zsh)\" -l
    fi
fi
# ==============================================
"

if ! grep -q "Auto-launch Zsh" "$BASHRC"; then
    echo "-> Injecting auto-start snippet into $BASHRC..."
    echo "$AUTOSTART_SNIPPET" >> "$BASHRC"
else
    echo "-> Auto-start snippet already exists in $BASHRC."
fi

# personal config
echo 'export UV_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"' >> ~/.zshrc
