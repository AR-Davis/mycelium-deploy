# Coven Deployment Scripts

Exact copy-paste command blocks for deploying the Mycelium mesh.

## Edge nodes

```bash
# On each Pi / edge node (run locally or via SSH)
curl -sL https://raw.githubusercontent.com/AR-Davis/mycelium-deploy/master/coven/deploy-edge-node.sh | bash -s crow
```

Replace `crow` with `wren` or `ember`.

## Hearth (TheTower)

```bash
# In MSYS2 / Git Bash on TheTower
curl -sL https://raw.githubusercontent.com/AR-Davis/mycelium-deploy/master/coven/deploy-hearth.sh | bash
```

## Deploy all known nodes from one host

```bash
# Edit deploy-all-nodes.sh with your SSH credentials, then:
./deploy-all-nodes.sh
```

## Per-device fingerprinting

Each wrapper sets a unique `MYCELIUM_NODE_ID`:
- `crow`, `wren`, `ember`, `hearth`

See `PER_DEVICE_FINGERPRINTING.md` in the repo root.
