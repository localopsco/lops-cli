#!/bin/bash

# ██       ██████   ██████  █████  ██       ██████  ██████  ███████      ██████ ██      ██
# ██      ██    ██ ██      ██   ██ ██      ██    ██ ██   ██ ██          ██      ██      ██
# ██      ██    ██ ██      ███████ ██      ██    ██ ██████  ███████     ██      ██      ██
# ██      ██    ██ ██      ██   ██ ██      ██    ██ ██           ██     ██      ██      ██
# ███████  ██████   ██████ ██   ██ ███████  ██████  ██      ███████      ██████ ███████ ██

# color codes
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# helpers
print() { echo " - $1"; }
warning() { echo "${YELLOW}$1${NC}"; }
error() { echo "${RED}$1${NC}"; }
success() { echo "${GREEN}$1${NC}"; }
clearLastLine() { tput cuu1 && tput el && tput el1; }
exitWithError() { error "\nError: $1"; exit 1; }

# Set repository details
PRODUCT_NAME="LocalOps CLI"
SUPPORT_EMAIL="help@localops.co"
DOCUMENTATION_LINK="https://docs.localops.co/cli"
OWNER="localopsco"
REPO="lops-cli"
BINARY_NAME="lops"

# Get the latest release from GitHub API
LATEST_RELEASE=$(curl --silent "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": "(.*)".*/\1/')

# Use the first argument as the version if provided, otherwise fallback to LATEST_RELEASE
VERSION=${1:-$LATEST_RELEASE}

# Determine OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
fi

# Construct the download URL and asset name
ASSET_NAME_WITHOUT_EXT="$OS-$ARCH"
ASSET_EXT="tar.gz"
OUT_DIR="$ASSET_NAME_WITHOUT_EXT"
ASSET_NAME="$ASSET_NAME_WITHOUT_EXT.$ASSET_EXT"

# Asset URL
DOWNLOAD_URL="https://github.com/$OWNER/$REPO/releases/download/$VERSION/$ASSET_NAME"

if [ -z "${VERSION}" ]; then
  exitWithError "Failed to install $PRODUCT_NAME. Unable to determine CLI version."
fi

# check if downloaded version is latest
if [ "$VERSION" != "$LATEST_RELEASE" ]; then
  warning "Latest version available: $LATEST_RELEASE"
fi

print "Installing $PRODUCT_NAME version $VERSION"

# Download the asset
print "Downloading asset $ASSET_NAME..."
HTTP_STATUS=$(curl --progress-bar -L -o "$ASSET_NAME" -w "%{http_code}" "$DOWNLOAD_URL")
STATUS=$?

# Clear the progress bar after request
clearLastLine

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

print "$ASSET_NAME downloaded successfully"

# Extract downloaded file
if [[ "$ASSET_NAME" == *.tar ]]; then
    print "Extracting $ASSET_NAME..."
    tar -xf "$ASSET_NAME"
else
    exitWithError "Unrecognized file format: $ASSET_NAME"
fi

print "Files extracted to $OUT_DIR/"

# Move the binary to /usr/local/bin (or another directory in the PATH)
print "Installing $PRODUCT_NAME. Enter password if requested"
sudo mv "$OUT_DIR/$BINARY_NAME" /usr/local/bin/

# Clean up the downloaded file
print "Performing cleanup. Removing downloaded files..."
rm -rf "$OUT_DIR"
rm "$ASSET_NAME"
print "Cleanup complete"

# Verify installation
print "Verifying installation..."
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
