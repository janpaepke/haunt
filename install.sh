#!/usr/bin/env bash
# haunt installer — downloads haunt to ~/.local/bin
set -euo pipefail

REPO="janpaepke/haunt"
INSTALL_DIR="${HOME}/.local/bin"
BIN_NAME="haunt"

echo "👻 Installing haunt..."

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: haunt requires macOS (it uses Ghostty's AppleScript API)." >&2
    exit 1
fi

# Check fzf
if ! command -v fzf &>/dev/null; then
    if command -v brew &>/dev/null; then
        read -rp "fzf is required but not installed. Install via Homebrew? [Y/n] " answer
        if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
            brew install fzf
        else
            echo "Aborted. Install fzf manually and re-run." >&2
            exit 1
        fi
    else
        echo "Error: fzf is required but not installed." >&2
        echo "Install it via Homebrew (https://brew.sh): brew install fzf" >&2
        echo "Or see https://github.com/junegunn/fzf#installation" >&2
        exit 1
    fi
fi

# Create install directory
mkdir -p "$INSTALL_DIR"

# If run from within the repo, symlink instead of downloading
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "${SCRIPT_DIR}/haunt" ]]; then
    ln -sf "${SCRIPT_DIR}/haunt" "${INSTALL_DIR}/${BIN_NAME}"
    echo "👻 Linked ${INSTALL_DIR}/${BIN_NAME} → ${SCRIPT_DIR}/haunt"
else
    curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/haunt" -o "${INSTALL_DIR}/${BIN_NAME}"
    chmod +x "${INSTALL_DIR}/${BIN_NAME}"
    echo "👻 Installed to ${INSTALL_DIR}/${BIN_NAME}"
fi

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    echo "Warning: ${INSTALL_DIR} is not in your \$PATH."
    echo "Add this to your shell config (~/.zshrc):"
    echo ""
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
fi
