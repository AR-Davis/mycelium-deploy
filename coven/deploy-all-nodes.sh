#!/bin/bash
# Deploy mycelium-slow-digest to all known Coven nodes via SSH
# Must be run from a host with SSH access to all nodes.
set -e

NODES="crow:192.168.100.30:crow wren:192.168.100.31:crow ember:192.168.100.50:kinch"

for spec in $NODES; do
  IFS=':' read -r NODE_ID HOST USER <<< "$spec"
  echo "--- Deploying $NODE_ID ($HOST) ---"
  ssh "$USER@$HOST" 'bash -s' -- < ./deploy-edge-node.sh "$NODE_ID"
done

echo "All edge nodes deployed."
