# Mycelium Deployment Packages

Staged and ready for SCP to any Coven device.

## Packages

| Package | Device | Arch | Binary Size | Role |
|---------|--------|------|-------------|------|
| shepherd-dell-latitude/ | Shepherd (Dell Latitude) | linux/amd64 | 10.3 MB | Full node (API + compute) |
| rhubarb-rpi5/ | Rhubarb (RPi5) | linux/arm64 | 9.6 MB | Full node (API + compute) |
| crow-wren-rpi-zero2w/ | Crow/Wren (RPi Zero 2W) | linux/armhf | 9.8 MB | Compute only (512MB RAM) |
| owl-rpi-model-b/ | Owl (RPi Model B) | linux/armhf | 9.8 MB | Compute only (512MB RAM) |

## Deploy To A Device

```bash
# From TheTower (192.168.100.x):
scp -r ~/Projects/mycelium-deploy/shepherd-dell-latitude/ user@device:~/mycelium/

# On the target device:
cd ~/mycelium && chmod +x mycelium mycelium-api install.sh
./install.sh
mycelium help
```

## Commands

| Command | What it does |
|---------|-------------|
| `mycelium` | Start full node (API + compute) |
| `mycelium api` | Start API gateway only |
| `mycelium node` | Start RPC compute node only |
| `mycelium status` | Check network health |
| `mycelium probe` | Query RPC device memory |
| `mycelium shell` | Interactive chat session |
| `mycelium stop` | Stop the network |
| `mycelium help` | Show all commands |

## Termux/Android (Pixel 2)

Pixel 2 uses a separate setup script — it builds rpc-server natively in Termux:

```bash
# From TheTower:
adb push ~/Projects/mycelium-api/scripts/mycelium-termux-setup.sh /sdcard/

# In Termux on Pixel 2:
bash /sdcard/mycelium-termux-setup.sh
mycelium node
```

## Config

Each package has `mycelium.yaml` with example IPs. Edit it on the target device to set real Tailscale IPs:

```yaml
nodes:
  - name: hearth
    host: 100.64.0.1    # Replace with real Tailscale IP
    port: 11434
    protocol: ollama
    weight: 100
  - name: ember
    host: 100.64.0.2    # Replace with real Tailscale IP
    port: 50052
    protocol: rpc
    weight: 10
```

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| MYCELIUM_PORT | 11435 | API gateway port |
| MYCELIUM_HOST | 0.0.0.0 | API gateway host |
| MYCELIUM_RPC_PORT | 50052 | RPC compute port |
| MYCELIUM_RPC_HOST | 0.0.0.0 | RPC compute host |

## GitHub

Source code: https://github.com/AR-Davis/prima_distributed_local/tree/main/mycelium-api

## Build From Source

```bash
cd ~/Projects/mycelium-api
make build-all    # cross-compile all architectures
make deploy       # create deployment packages here
```
