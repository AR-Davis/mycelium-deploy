#!/bin/bash
# mycelium installer for shepherd-dell-latitude
set -e

INSTALL_DIR="$HOME/.local/bin"
MYCELIUM_DIR="$HOME/.mycelium"

mkdir -p "$INSTALL_DIR" "$MYCELIUM_DIR"

# Copy binary
cp mycelium-api "$MYCELIUM_DIR/"
chmod +x "$MYCELIUM_DIR/mycelium-api"

# Copy config
cp mycelium.yaml "$MYCELIUM_DIR/"

# Copy launcher
cp mycelium "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/mycelium"

# Add to PATH if not already
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo 'export PATH="$INSTALL_DIR:$PATH"' >> "$HOME/.bashrc"
    export PATH="$INSTALL_DIR:$PATH"
fi

echo "Installed. Run 'mycelium help' to get started."
