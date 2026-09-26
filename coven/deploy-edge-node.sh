#!/bin/bash
# Deploy Mycelium Slow Digest on an edge node
# Usage: ./deploy-edge-node.sh <NODE_ID>
# Example: ./deploy-edge-node.sh crow
set -e

NODE_ID="${1:-}"
if [ -z "$NODE_ID" ]; then
  echo "Usage: $0 <NODE_ID>"
  echo "Valid IDs: crow, wren, ember"
  exit 1
fi

REPO="https://github.com/AR-Davis/mycelium-slow-digest.git"

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

SRC="$HOME/mycelium-slow-digest"
DEST="$HOME/mycelium-shared/digests"
cp "$SRC/digest_watcher.py" "$DEST/"
cp "$SRC/export_digest_dashboard.py" "$DEST/"
cp "$SRC/agents.yaml" "$DEST/"
cp "$SRC/wrappers/digest-watcher.$NODE_ID.sh" "$HOME/.local/bin/digest-watcher.sh"
chmod +x "$HOME/.local/bin/digest-watcher.sh"

# Add crontab entry if not present
CRON_LINE="*/15 * * * * /home/\$USER/.local/bin/digest-watcher.sh"
if ! crontab -l 2>/dev/null | grep -q "digest-watcher.sh"; then
  (crontab -l 2>/dev/null || true; echo "$CRON_LINE") | crontab -
  echo "[$NODE_ID] Added crontab entry."
else
  echo "[$NODE_ID] Crontab entry already exists."
fi

echo "[$NODE_ID] Deployment complete."
