#!/bin/bash
# Deploy Mycelium Slow Digest on Hearth (TheTower / Windows + MSYS)
# Run from MSYS2 / Git Bash
set -e

NODE_ID="hearth"
REPO="https://github.com/AR-Davis/mycelium-slow-digest.git"

# Ensure mycelium-shared directory exists
mkdir -p "$HOME/mycelium-shared/digests"
mkdir -p "$HOME/.local/bin"

# Clone or update
cd "$HOME"
if [ -d mycelium-slow-digest/.git ]; then
  cd mycelium-slow-digest
  git pull --quiet
else
  git clone --depth 1 "$REPO" mycelium-slow-digest
fi

# Copy canonical files
SRC="$HOME/mycelium-slow-digest"
DEST="$HOME/mycelium-shared/digests"
cp "$SRC/digest_watcher.py" "$DEST/"
cp "$SRC/export_digest_dashboard.py" "$DEST/"
cp "$SRC/agents.yaml" "$DEST/"
cp "$SRC/wrappers/digest-watcher.hearth.sh" "$HOME/.local/bin/digest-watcher.sh"

# Python dependencies
python3 -m pip install --user pyyaml requests 2>/dev/null || python -m pip install --user pyyaml requests 2>/dev/null || true

echo "[$NODE_ID] Deployment complete. Add to crontab/Task Scheduler:"
echo "  bash $HOME/.local/bin/digest-watcher.sh"
