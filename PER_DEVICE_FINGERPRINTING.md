# Per-Device Fingerprinting

Each mesh node must identify uniquely so responses and settlements can be traced.

| Node | IP | Tailscale | `MYCELIUM_NODE_ID` | Role |
|------|----|-----------|-------------------|------|
| hearth | 192.168.100.29 | 100.117.183.84 | `hearth` | Local Ollama, settlement |
| crow | 192.168.100.30 | 100.97.71.98 | `crow` | Tier-1 responder |
| wren | 192.168.100.31 | 100.83.89.53 | `wren` | Tier-1 responder |
| ember | 192.168.100.50 | 100.90.116.1 | `ember` | Tier-2 responder/settler |

Crontab entries on crow/wren use `NODE_NAME=<node>` for base agents.
Digest watcher wrappers set `MYCELIUM_NODE_ID=<node>`.
Response files: `<node_id>_<model>.md`
Settlement files: `<node_id>_<model>_settlement_<n>.md`
