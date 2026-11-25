#!/usr/bin/env bash
# Install ssh.lua into the Rex configuration directory and add the require line.
set -euo pipefail

CONFIG_DIR="${REX_CONFIG_DIR:-$HOME/.config/rex}"
mkdir -p "$CONFIG_DIR"

cp "$(dirname "$0")/ssh.lua" "$CONFIG_DIR/ssh.lua"

if [ -f "$CONFIG_DIR/init.lua" ] && ! grep -q 'require("ssh")' "$CONFIG_DIR/init.lua"; then
  echo 'require("ssh")' >> "$CONFIG_DIR/init.lua"
elif [ ! -f "$CONFIG_DIR/init.lua" ]; then
  echo 'require("ssh")' > "$CONFIG_DIR/init.lua"
fi

echo "Installed to $CONFIG_DIR/ssh.lua"
echo "Reload with: rex config reload"
echo "Trigger: ctrl+alt+s, command palette \"SSH: Connect Host…\", or: rex do ssh_open"
