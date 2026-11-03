#!/bin/bash
# Install the yazi plugins pinned in yazi/package.toml.
# The plugins are public and .gitconfig only rewrites pushes to SSH, so this works over HTTPS without keys.
set -euo pipefail

ya pkg install

echo "✓ Yazi plugins installed!"
