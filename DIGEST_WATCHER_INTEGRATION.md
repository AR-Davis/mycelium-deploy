# Integrating Mycelium Slow Digest on Phone Nodes

1. Clone `AR-Davis/mycelium-slow-digest`
2. Copy the appropriate wrapper from `wrappers/` to `~/.local/bin/digest-watcher.sh`
3. Set `MYCELIUM_NODE_ID` to a unique value (e.g., `g4`, `pixel`, `raven`)
4. Add a crontab entry or Termux:Boot script to run it periodically

Pixel 2 is currently unrootable and acts as a non-rooted control station.
