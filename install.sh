#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Codeforward Dev Tools · Bootstrap Installer
#
# Minimal public script that fetches and runs the private tooling.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/codeforward-dev-tools/main/install.sh)"
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# --- Configuration ---
REPO_OWNER="codeforward-bv"
PRIVATE_REPO="codeforward-dev-tools-private"
PRIVATE_REPO_SSH="git@github.com:$REPO_OWNER/$PRIVATE_REPO.git"
BRANCH="${CF_DEV_TOOLS_BRANCH:-main}"

INSTALL_DIR="$HOME/.local/share/codeforward-dev-tools"
BIN_DIR="$HOME/.local/bin"
BIN_NAME="cf-dev-tools"

# --- Colors ---
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

# --- Helpers ---
info()  { printf "${BLUE}[info]${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}  ✓${NC} %s\n" "$*"; }
fail()  { printf "${RED}[error]${NC} %s\n" "$*" >&2; exit 1; }

# --- Main ---

echo ""
info "Installing Codeforward Dev Tools..."
echo ""

# Check prerequisites
info "Checking prerequisites..."

command -v git &>/dev/null || fail "git is required. Install Xcode Command Line Tools: xcode-select --install"
ok "git"

# Install gh if missing (macOS)
if ! command -v gh &>/dev/null; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
        if command -v brew &>/dev/null; then
            info "Installing GitHub CLI via Homebrew..."
            brew install gh
        else
            fail "GitHub CLI (gh) is required. Install Homebrew first, then: brew install gh"
        fi
    else
        fail "GitHub CLI (gh) is required. Install it: https://cli.github.com/"
    fi
fi
ok "gh (GitHub CLI)"

# Check GitHub authentication
if ! gh auth status &>/dev/null; then
    info "GitHub authentication required..."
    gh auth login || fail "GitHub authentication failed"
fi
ok "GitHub authenticated"

# Clone or update private repo
mkdir -p "$INSTALL_DIR"
echo ""

if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating codeforward-dev-tools..."
    git -C "$INSTALL_DIR" fetch origin --quiet
    git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH" --quiet
    ok "Updated to latest"
else
    info "Installing codeforward-dev-tools..."
    rm -rf "$INSTALL_DIR"

    if git clone --quiet --branch "$BRANCH" "$PRIVATE_REPO_SSH" "$INSTALL_DIR" 2>/dev/null; then
        ok "Cloned via SSH"
    elif gh repo clone "$REPO_OWNER/$PRIVATE_REPO" "$INSTALL_DIR" -- --quiet --branch "$BRANCH" 2>/dev/null; then
        ok "Cloned via gh CLI"
    else
        fail "Failed to clone private repo. Ensure you have access to $REPO_OWNER/$PRIVATE_REPO"
    fi
fi

# Ensure uv is installed for Python management
if ! command -v uv &>/dev/null; then
    if [[ "$(uname -s)" == "Darwin" ]] && command -v brew &>/dev/null; then
        info "Installing uv via Homebrew..."
        brew install uv
    else
        info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi
ok "uv"

# Create/update venv and install dependencies
VENV_DIR="$INSTALL_DIR/.venv"
if [[ ! -d "$VENV_DIR" ]]; then
    info "Creating virtual environment..."
    uv venv "$VENV_DIR" --quiet
fi

info "Installing dependencies..."
uv pip install --quiet --python "$VENV_DIR/bin/python" -r "$INSTALL_DIR/requirements.txt"
ok "Dependencies installed"

# Install wrapper to ~/.local/bin
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/$BIN_NAME" << 'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/codeforward-dev-tools"
VENV_PY="$INSTALL_DIR/.venv/bin/python"
SCRIPT="$INSTALL_DIR/cf-dev-tools"

if [[ ! -x "$VENV_PY" ]]; then
    echo "ERROR: Virtual environment not found. Re-run the installer."
    exit 1
fi

exec "$VENV_PY" "$SCRIPT" "$@"
WRAPPER

chmod +x "$BIN_DIR/$BIN_NAME"
ok "Installed $BIN_NAME to $BIN_DIR"

# Ensure PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    ZSHRC="$HOME/.zshrc"
    PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
    if ! grep -Fq "$PATH_LINE" "$ZSHRC" 2>/dev/null; then
        echo "" >> "$ZSHRC"
        echo "# Added by Codeforward Dev Tools" >> "$ZSHRC"
        echo "$PATH_LINE" >> "$ZSHRC"
        info "Added ~/.local/bin to PATH in $ZSHRC"
    fi
fi

echo ""
ok "Installation complete!"
echo ""
info "Run 'cf-dev-tools' to start"
echo ""
