#!/bin/bash

# ██       ██████   ██████  █████  ██       ██████  ██████  ███████      ██████ ██      ██
# ██      ██    ██ ██      ██   ██ ██      ██    ██ ██   ██ ██          ██      ██      ██
# ██      ██    ██ ██      ███████ ██      ██    ██ ██████  ███████     ██      ██      ██
# ██      ██    ██ ██      ██   ██ ██      ██    ██ ██           ██     ██      ██      ██
# ███████  ██████   ██████ ██   ██ ███████  ██████  ██      ███████      ██████ ███████ ██

set -e

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
  is_tty() { true; }
else
  is_tty() { false; }
fi

setup_color() {
  # Only use colors if connected to a terminal
  if is_tty; then
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    return
  else
    YELLOW=''
    RED=''
    GREEN=''
    NC=''
  fi
}

setup_color

# helpers
info() { echo " - $1"; }
newLine() { echo ""; }
warning() { printf "${YELLOW}$1${NC}\n"; }

PRODUCT_NAME="LocalOps CLI"
BINARY_NAME="ops"
BIN_PATH="/usr/local/bin"

while true; do
    read -r -p "Are you sure to uninstall $PRODUCT_NAME? (y/n): " choice
    case "$choice" in
        y|Y ) break;;
        n|N ) exit 1;;
        * ) echo "Invalid input. Please enter 'y' or 'n'.";;
    esac
done

newLine
info "Enter your password to uninstall $BINARY_NAME cli"

# Ask for password upfront
sudo -v

info "Removing binary from PATH"
sudo rm -f "$BIN_PATH/$BINARY_NAME"

info "Cleanup residual files"

warning "\n$PRODUCT_NAME uninstalled successfully :(\n"
