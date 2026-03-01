#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Codeforward Dev Tools · Bootstrap Installer
#
# Minimal public script: checks git/gh, clones the private repo,
# then hands off to scripts/setup.sh for everything else.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/cf-dev-tools/main/install.sh)"
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# --- Configuration ---
REPO_OWNER="codeforward-bv"
PRIVATE_REPO="cf-dev-tools-private"
PRIVATE_REPO_SSH="git@github.com:$REPO_OWNER/$PRIVATE_REPO.git"
BRANCH="${CF_DEV_TOOLS_BRANCH:-main}"

INSTALL_DIR="$HOME/.local/share/cf-dev-tools"

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
info "Codeforward Dev Tools Installer"
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
    info "Updating cf-dev-tools..."
    git -C "$INSTALL_DIR" fetch origin --quiet
    git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH" --quiet
    ok "Updated to latest"
else
    info "Installing cf-dev-tools..."
    rm -rf "$INSTALL_DIR"

    if git clone --quiet --branch "$BRANCH" "$PRIVATE_REPO_SSH" "$INSTALL_DIR" 2>/dev/null; then
        ok "Cloned via SSH"
    elif gh repo clone "$REPO_OWNER/$PRIVATE_REPO" "$INSTALL_DIR" -- --quiet --branch "$BRANCH" 2>/dev/null; then
        ok "Cloned via gh CLI"
    else
        fail "Failed to clone private repo. Ensure you have access to $REPO_OWNER/$PRIVATE_REPO"
    fi
fi

# Hand off to private setup script
exec "$INSTALL_DIR/scripts/setup.sh"
