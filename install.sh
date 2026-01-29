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
PRIVATE_REPO_HTTPS="https://github.com/$REPO_OWNER/$PRIVATE_REPO.git"
BRANCH="${CF_DEV_TOOLS_BRANCH:-main}"

INSTALL_DIR="$HOME/.local/share/codeforward-dev-tools"
BIN_DIR="$HOME/.local/bin"
BIN_NAME="cf-dev-tools"

# --- Colors ---
NC='\033[0m'
TEAL='\033[38;5;37m'
WHITE='\033[38;5;255m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

# --- Banner ---
BANNER_LINES=(
    " ██████╗ ██╗      ██████╗ ██████╗ ██████╗ ███████╗███████╗ ██████╗ ██████╗ ██╗    ██╗ █████╗ ██████╗ ██████╗ "
    "██╔════╝ ╚██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔══██╗"
    "██║       ╚██╗   ██║     ██║   ██║██║  ██║█████╗  █████╗  ██║   ██║██████╔╝██║ █╗ ██║███████║██████╔╝██║  ██║"
    "██║       ██╔╝   ██║     ██║   ██║██║  ██║██╔══╝  ██╔══╝  ██║   ██║██╔══██╗██║███╗██║██╔══██║██╔══██╗██║  ██║"
    "╚██████╗ ██╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗██║     ╚██████╔╝██║  ██║╚███╔███╔╝██║  ██║██║  ██║██████╔╝"
    " ╚═════╝ ╚═╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ "
    "                                        Codeforward Dev Tools                                                 "
)

CHEVRON_RANGES=("9 12" "9 13" "10 14" "10 14" "9 13" "9 12" "")

# --- Helpers ---
info()  { printf "${BLUE}[info]${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}  ✓${NC} %s\n" "$*"; }
fail()  { printf "${RED}[error]${NC} %s\n" "$*" >&2; exit 1; }

move_cursor_up() { printf '\033[%dA' "$1"; }

print_banner_colored() {
    local teal_color="$1" white_color="$2" row_idx=0
    for line in "${BANNER_LINES[@]}"; do
        local range="${CHEVRON_RANGES[$row_idx]}"
        if [[ -n "$range" ]]; then
            local start end
            read -r start end <<< "$range"
            local before="${line:0:$start}"
            local chevron="${line:$start:$((end - start))}"
            local after="${line:$end}"
            printf '%b%s%b%s%b%s%b\n' "$teal_color" "$before" "$white_color" "$chevron" "$teal_color" "$after" "$NC"
        else
            printf '%b%s%b\n' "$teal_color" "$line" "$NC"
        fi
        ((row_idx++))
    done
}

print_banner_knight_rider() {
    local highlight_pos="$1"
    local teal='\033[38;5;37m' white='\033[38;5;255m'
    local gradient_colors=('\033[38;5;37m' '\033[38;5;44m' '\033[38;5;51m' '\033[38;5;255m' '\033[38;5;51m' '\033[38;5;44m' '\033[38;5;37m')
    local gradient_width=${#gradient_colors[@]} row_idx=0

    for line in "${BANNER_LINES[@]}"; do
        local range="${CHEVRON_RANGES[$row_idx]}" chev_start=-1 chev_end=-1
        if [[ -n "$range" ]]; then read -r chev_start chev_end <<< "$range"; fi

        local colored_line="" i=0 len=${#line}
        while [[ $i -lt $len ]]; do
            local char="${line:$i:1}" color
            if [[ $chev_start -ge 0 && $i -ge $chev_start && $i -lt $chev_end ]]; then
                color="$white"
            else
                local dist=$((highlight_pos - i))
                [[ $dist -lt 0 ]] && dist=$((-dist))
                if [[ $dist -lt $gradient_width ]]; then color="${gradient_colors[$dist]}"; else color="$teal"; fi
            fi
            colored_line+="${color}${char}"
            ((i++))
        done
        printf '%b%b\n' "$colored_line" "$NC"
        ((row_idx++))
    done
}

banner() {
    if [[ ! -t 1 ]]; then print_banner_colored "$TEAL" "$WHITE"; echo ""; return; fi

    local banner_height=${#BANNER_LINES[@]} banner_width=${#BANNER_LINES[0]}
    local teal_shades=(23 29 30 31 35 36 37 43 44 51)
    local white_shades=(240 244 247 249 251 252 253 254 255 255)

    # Fade in
    for shade_idx in {0..9}; do
        local teal_color="\033[38;5;${teal_shades[$shade_idx]}m"
        local white_color="\033[38;5;${white_shades[$shade_idx]}m"
        print_banner_colored "$teal_color" "$white_color"
        sleep 0.05
        [[ $shade_idx -lt 9 ]] && move_cursor_up "$banner_height"
    done

    # Knight Rider sweep
    local step_size=4 delay=0.008
    for ((pos = 0; pos <= banner_width + 7; pos += step_size)); do
        move_cursor_up "$banner_height"; print_banner_knight_rider "$pos"; sleep "$delay"
    done
    for ((pos = banner_width + 6; pos >= -7; pos -= step_size)); do
        move_cursor_up "$banner_height"; print_banner_knight_rider "$pos"; sleep "$delay"
    done

    move_cursor_up "$banner_height"
    print_banner_colored "$TEAL" "$WHITE"
    echo ""
}

# --- Main ---

banner

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
info "Run 'cf-dev-tools' to start (may need to restart terminal)"
echo ""

# Run the tool immediately
exec "$BIN_DIR/$BIN_NAME"
