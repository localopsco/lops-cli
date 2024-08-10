#!/bin/bash

# Set repository details
OWNER="localopsco"
REPO="lops-cli"

# Get the latest release from GitHub API
LATEST_RELEASE=$(curl --silent "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

 # Determine OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
fi

# Construct the download URL and asset name
ASSET_NAME="$OS-$ARCH".tar
OUTPUT_DIRECTORY="$OS-$ARCH"

echo "Installing LocalOps CLI version $LATEST_RELEASE"

DOWNLOAD_URL="https://github.com/$OWNER/$REPO/releases/download/$LATEST_RELEASE/$ASSET_NAME"

# Download the asset
echo "Downloading $ASSET_NAME from release $LATEST_RELEASE..."
curl -L -o "$ASSET_NAME" "$DOWNLOAD_URL"

# Extract downloaded file
if [[ "$ASSET_NAME" == *.tar ]]; then
    echo "Extracting $ASSET_NAME..."
    tar -xvf "$ASSET_NAME"
else
    echo "Unrecognized file format: $ASSET_NAME"
    exit 1
fi

# Move the binary to /usr/local/bin (or another directory in the PATH)
BINARY_NAME="lops"
sudo mv "$OUTPUT_DIRECTORY/$BINARY_NAME" /usr/local/bin/

# Clean up the downloaded file
rm -rf "$OUTPUT_DIRECTORY"
rm "$ASSET_NAME"

# Verify installation
if command -v "$BINARY_NAME" &> /dev/null; then
    echo "$BINARY_NAME has been installed successfully and added to your PATH."
    echo ""
    echo ""
    echo "                   ___           ___           ___                         ___           ___         ___                    ___                                "
    echo "                  /\  \         /\__\         /\  \                       /\  \         /\  \       /\__\                  /\__\                               "
    echo "                 /::\  \       /:/  /        /::\  \                     /::\  \       /::\  \     /:/ _/_                /:/  /                      ___      "
    echo "                /:/\:\  \     /:/  /        /:/\:\  \                   /:/\:\  \     /:/\:\__\   /:/ /\  \              /:/  /                      /\__\     "
    echo " ___     ___   /:/  \:\  \   /:/  /  ___   /:/ /::\  \   ___     ___   /:/  \:\  \   /:/ /:/  /  /:/ /::\  \            /:/  /  ___   ___     ___   /:/__/     "
    echo "/\  \   /\__\ /:/__/ \:\__\ /:/__/  /\__\ /:/_/:/\:\__\ /\  \   /\__\ /:/__/ \:\__\ /:/_/:/  /  /:/_/:/\:\__\          /:/__/  /\__\ /\  \   /\__\ /::\  \     "
    echo "\:\  \ /:/  / \:\  \ /:/  / \:\  \ /:/  / \:\/:/  \/__/ \:\  \ /:/  / \:\  \ /:/  / \:\/:/  /   \:\/:/ /:/  /          \:\  \ /:/  / \:\  \ /:/  / \/\:\  \__  "
    echo " \:\  /:/  /   \:\  /:/  /   \:\  /:/  /   \::/__/       \:\  /:/  /   \:\  /:/  /   \::/__/     \::/ /:/  /            \:\  /:/  /   \:\  /:/  /   ~~\:\/\__\ "
    echo "  \:\/:/  /     \:\/:/  /     \:\/:/  /     \:\  \        \:\/:/  /     \:\/:/  /     \:\  \      \/_/:/  /              \:\/:/  /     \:\/:/  /       \::/  / "
    echo "   \::/  /       \::/  /       \::/  /       \:\__\        \::/  /       \::/  /       \:\__\       /:/  /                \::/  /       \::/  /        /:/  /  "
    echo "    \/__/         \/__/         \/__/         \/__/         \/__/         \/__/         \/__/       \/__/                  \/__/         \/__/         \/__/   "

else
    echo "Installation failed. Please check the script and try again."
fi
