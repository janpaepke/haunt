#!/usr/bin/env bash
# haunt installer — downloads haunt to ~/.local/share/haunt and symlinks the binary
set -euo pipefail

REPO="janpaepke/haunt"
INSTALL_DIR="${HOME}/.local/share/haunt"
BIN_DIR="${HOME}/.local/bin"
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

# If run from within the repo, symlink directly
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "${SCRIPT_DIR}/haunt" && -d "${SCRIPT_DIR}/hooks" ]]; then
    mkdir -p "$BIN_DIR"
    ln -sf "${SCRIPT_DIR}/haunt" "${BIN_DIR}/${BIN_NAME}"
    echo "👻 Linked ${BIN_DIR}/${BIN_NAME} → ${SCRIPT_DIR}/haunt (dev mode)"
else
    # Fetch latest release tag
    latest=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | head -1 | sed 's/.*: "//;s/".*//')
    if [[ -z "$latest" ]]; then
        echo "Error: could not determine latest release." >&2
        exit 1
    fi
    echo "Downloading ${latest}..."

    # Clean previous install
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    # Download and extract release tarball
    curl -fsSL "https://github.com/${REPO}/archive/refs/tags/${latest}.tar.gz" \
        | tar xz -C "$INSTALL_DIR" --strip-components=1

    # Symlink binary
    mkdir -p "$BIN_DIR"
    ln -sf "${INSTALL_DIR}/haunt" "${BIN_DIR}/${BIN_NAME}"
    echo "👻 Installed haunt ${latest} to ${INSTALL_DIR}"
fi

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    echo ""
    echo "Warning: ${BIN_DIR} is not in your \$PATH."
    echo "Add this to your shell config (~/.zshrc):"
    echo ""
    echo "  export PATH=\"${BIN_DIR}:\$PATH\""
fi
