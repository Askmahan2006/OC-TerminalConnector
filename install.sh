#!/usr/bin/env bash
# =============================================================================
# install.sh - install (or uninstall) vpn-cli
#
#   ./install.sh               Install to /usr/local/bin
#   ./install.sh --uninstall   Remove the installed script (config is kept)
#
# Run it as your normal user (NOT with sudo). It calls sudo itself only when
# needed, so the config file ends up in YOUR home directory.
# =============================================================================

set -eu

PREFIX="${PREFIX:-/usr/local}"                 # override: PREFIX=$HOME/.local ./install.sh
BIN_DIR="$PREFIX/bin"
TARGET="$BIN_DIR/vpn"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/vpn-cli/config"

# Directory this script lives in (so it works from any current directory).
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

# Refuse to run as root: $HOME would point to /root and the config would
# be created in the wrong place.
if [ "$(id -u)" -eq 0 ]; then
    echo "Please run this script as a normal user, not root/sudo." >&2
    exit 1
fi

# Use sudo only if we cannot write to the install directory.
SUDO=""
if [ ! -w "$BIN_DIR" ] 2>/dev/null; then
    SUDO="sudo"
fi

# ---- Uninstall --------------------------------------------------------------
if [ "${1:-}" = "--uninstall" ]; then
    $SUDO rm -f "$TARGET"
    echo "Removed $TARGET"
    echo "Your config ($CONFIG_FILE) was kept. Delete it manually if you want."
    exit 0
fi

# ---- Check dependencies -----------------------------------------------------
missing=""
for cmd in bash openconnect expect sudo setsid; do
    command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done

if [ -n "$missing" ]; then
    echo "Missing dependencies:$missing"
    echo "Install them first, for example:"
    echo "  Debian/Ubuntu : sudo apt install openconnect expect"
    echo "  Fedora/RHEL   : sudo dnf install openconnect expect"
    echo "  Arch          : sudo pacman -S openconnect expect"
    exit 1
fi

# ---- Install the script -----------------------------------------------------
$SUDO mkdir -p "$BIN_DIR"
$SUDO install -m 755 "$SRC_DIR/bin/vpn" "$TARGET"
echo "Installed $TARGET"

# ---- Config ------------------------------------------------------------------
# No config is created here. The first time you run `vpn`, it asks for your
# server, username and password and saves them (private, chmod 600) to:
#   ~/.config/vpn-cli/config
if [ -f "$CONFIG_FILE" ]; then
    echo "Existing config found, leaving it untouched: $CONFIG_FILE"
fi

echo
echo "Done. Run 'vpn' to connect. On first run it will ask for your login details."
