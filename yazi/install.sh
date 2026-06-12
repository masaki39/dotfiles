#!/bin/bash

# Install yazi plugins (fallback to HTTPS if SSH not configured)
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  ya pkg install
else
  GIT_CONFIG_GLOBAL=/dev/null git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true
  cat > /tmp/ya-https-gitconfig << 'EOF'
[url "https://github.com/"]
	insteadOf = git@github.com:
EOF
  GIT_CONFIG_GLOBAL=/tmp/ya-https-gitconfig ya pkg install
fi

echo "✓ Yazi plugins installed!"
