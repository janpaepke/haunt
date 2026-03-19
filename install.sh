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
    echo "Error: fzf is required. Install it first: brew install fzf" >&2
    exit 1
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
