# Ember Node Setup

Hardware: x86_64 Ubuntu, 2 GB RAM
Role: Hearth-Archive / library host + tier-2 responder/settler
Network: 192.168.100.50 / Tailscale `myceliumnetwork` (100.90.116.1)

## Services

- `mycelium-rpc.service` — RPC server on `0.0.0.0:50052`
- Slow Digest watcher via crontab: `*/30 * * * * ~/.local/bin/digest-watcher.sh`

## Storage

Root volume expanded to 296 GB with ~262 GB free.
`/srv/mycelium/{library,models,scratch}` created.

## Firewall

```bash
sudo ufw allow from 192.168.100.0/24 to any port 50052
```

## Library

- `mycelium-library` Syncthing folder: TheTower `D:\mycelium-library` ↔ Ember `/srv/mycelium/library`
- NH corpus extracted to `/srv/mycelium/library/nh-corpus/`
