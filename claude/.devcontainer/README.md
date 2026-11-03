# Claude Code Sandbox Devcontainer

Claude Code devcontainer definition, based on the official repository (with a local comment in `devcontainer.json`).

- **Source**: https://github.com/anthropics/claude-code/tree/main/.devcontainer
- **Docs**: https://docs.anthropic.com/en/docs/claude-code/devcontainer

## Files

| File | Contents |
|------|----------|
| `devcontainer.json` | Container settings (VS Code extensions, volumes, etc.) |
| `Dockerfile` | Image definition (Node.js, Claude Code CLI, zsh, git-delta, etc.) |
| `init-firewall.sh` | Firewall setup at startup (allowlist based) |

## Updating

```bash
cd "$DOTFILES/claude/.devcontainer"
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/devcontainer.json
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/Dockerfile
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/init-firewall.sh
```

`curl` overwrites the local changes: re-apply the comment in `devcontainer.json` (check with `git diff`)
before committing.
