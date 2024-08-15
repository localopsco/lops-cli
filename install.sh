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
warning() { printf "${YELLOW}$1${NC}\n"; }
error() { printf "${RED}$1${NC}\n"; }
success() { printf "${GREEN}$1${NC}\n"; }
clearLastLine() { tput cuu1 && tput el && tput el1; }
exitWithError() { error "\nError: $1"; exit 1; }

# Function to check if sudo access is available
has_sudo_access() {
    sudo -n true 2>/dev/null
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Determine OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
fi

OS_NAME=$OS

if [ "$OS" == 'darwin' ]; then
  OS_NAME='macos'
fi

# Set repository details
PRODUCT_NAME="LocalOps CLI"
SUPPORT_EMAIL="help@localops.co"
DOCUMENTATION_LINK="https://docs.localops.co/cli/install-$OS_NAME"
OWNER="localopsco"
REPO="lops-cli"
BINARY_NAME="lops"
TEMP_DIR=$(mktemp -d)
BIN_PATH="/usr/local/bin/"

# Get the latest release from GitHub API
LATEST_RELEASE=$(curl --silent "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": "(.*)".*/\1/')

# Use the first argument as the version if provided, otherwise fallback to LATEST_RELEASE
VERSION=${1:-$LATEST_RELEASE}

# Construct the download URL and asset name
ASSET_NAME_WITHOUT_EXT="${BINARY_NAME}-$OS-$ARCH"
ASSET_EXT="tar.gz"
ASSET_NAME="$ASSET_NAME_WITHOUT_EXT.$ASSET_EXT"
DOWNLOAD_TARGET="$TEMP_DIR/$ASSET_NAME"

# Asset URL
DOWNLOAD_URL="https://github.com/$OWNER/$REPO/releases/download/$VERSION/$ASSET_NAME"

if [ -z "${VERSION}" ]; then
    exitWithError "Failed to install $PRODUCT_NAME. Unable to determine CLI version."
fi

# check if downloaded version is latest
if [ "$VERSION" != "$LATEST_RELEASE" ]; then
    warning "\nLatest version available: $LATEST_RELEASE\n"
fi

info "Installing $PRODUCT_NAME version $VERSION"

if is_tty; then
    # If output is a TTY, show progress bar
    CURL_PROGRESS_OPTION="--progress-bar"
else
    # If output is not a TTY, disable progress bar
    CURL_PROGRESS_OPTION="--no-progress-meter"
fi

# Download the asset
info "Downloading asset $ASSET_NAME..."
HTTP_STATUS=$(curl $CURL_PROGRESS_OPTION -L -o "$DOWNLOAD_TARGET" -w "%{http_code}" "$DOWNLOAD_URL")
STATUS=$?

if is_tty; then
    # Progress is enable only if on tty
    # Clear the progress bar after request
    clearLastLine
fi

# Cleanup asset if download fails
if [ $STATUS -ne 0 ] || [ "$HTTP_STATUS" -ne 200 ]; then
    rm "$ASSET_NAME"
fi

if [ $STATUS -ne 0 ]; then
    exitWithError "Request failed CURL status code: $STATUS"
elif [ "$HTTP_STATUS" -eq 404 ]; then
    exitWithError "Unable to download asset. Version '$VERSION' doesn't exist"
elif [ "$HTTP_STATUS" -ne 200 ]; then
    exitWithError "HTTP request failed with HTTP status code: $HTTP_STATUS"
fi

info "$ASSET_NAME downloaded successfully"

# Extract downloaded file
if [[ "$ASSET_NAME" == *.$ASSET_EXT ]]; then
    info "Extracting $ASSET_NAME..."
    tar -xf "$DOWNLOAD_TARGET" -C $TEMP_DIR
else
    exitWithError "Unrecognized file format: $ASSET_NAME"
fi

info "Files extracted to temp directory: $TEMP_DIR/"

# Move the binary to /usr/local/bin
info "Installing $PRODUCT_NAME."
MOVE_BINARY_NOTICE="Moving $BINARY_NAME cli to your PATH"
if ! has_sudo_access; then
    MOVE_BINARY_NOTICE+=". Enter your password to continue"
fi
info "$MOVE_BINARY_NOTICE"
sudo mv "$TEMP_DIR/$BINARY_NAME" $BIN_PATH

# Clean up the downloaded file
info "Performing cleanup. Removing downloaded files..."
rm -rf "$TEMP_DIR"
info "Cleanup complete"

# Verify installation
info "Verifying installation..."
if command -v "$BINARY_NAME" &> /dev/null; then
    success "🚀 $BINARY_NAME has been installed successfully and added to your PATH."
    echo ""
    echo "  __         ______     ______     ______     __         ______     ______   ______     "
    echo " /\ \       /\  __ \   /\  ___\   /\  __ \   /\ \       /\  __ \   /\  == \ /\  ___\    "
    echo " \ \ \____  \ \ \/\ \  \ \ \____  \ \  __ \  \ \ \____  \ \ \/\ \  \ \  _-/ \ \___  \   "
    echo "  \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_____\  \ \_\    \/\_____\  "
    echo "   \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_/     \/_____/  "
    echo ""
    echo ""
    echo "Usage:"
    echo "   Run '$BINARY_NAME help' to see all available commands"
    echo ""
    echo "Documentation:"
    echo "   Visit $DOCUMENTATION_LINK to know more about $PRODUCT_NAME"
    echo ""
    echo "Support:"
    echo "   Reach us at $SUPPORT_EMAIL"
    echo ""
else
    exitWithError "$PRODUCT_NAME installation failed. Please try again or contact us at $SUPPORT_EMAIL"
fi
