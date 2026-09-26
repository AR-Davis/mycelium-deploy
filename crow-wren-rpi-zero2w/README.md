# Mycelium Network — crow-wren-rpi-zero2w

Raspberry Pi Zero 2W. Compute node only (512MB RAM).

## Quick Start

1. Copy this directory to the device
2. Run: `./mycelium api` (for access point) or `./mycelium node` (for compute only)
3. Or just: `./mycelium` (starts both)

## Configuration

Edit `mycelium.yaml` to set:
- Node addresses (use Tailscale IPs for remote nodes)
- Routing profiles (Huginn/Muninn/Skald)
- Timeouts and weights

## Environment Variables

- `MYCELIUM_PORT` — API port (default: 11435)
- `MYCELIUM_HOST` — API host (default: 0.0.0.0)
- `MYCELIUM_RPC_PORT` — RPC compute port (default: 50052)
- `MYCELIUM_RPC_HOST` — RPC compute host (default: 0.0.0.0)
- `MYCELIUM_CONFIG` — Path to config YAML
- `MYCELIUM_BIN` — Path to mycelium-api binary

## Architecture

Binary: mycelium-api-linux-armhf (linux-armhf)
Arch: armhf
Role: node

## The Mycelium Network

Every machine is both an access point and a compute node.
Walk to any machine, open a terminal, type `mycelium`.
