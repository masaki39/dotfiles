# Claude Code Sandbox Devcontainer

Claude Code devcontainer definition, taken as-is from the official repository.

- **Source**: https://github.com/anthropics/claude-code/tree/main/.devcontainer
- **Docs**: https://docs.anthropic.com/en/docs/claude-code/devcontainer

## Files

| File | Contents |
|------|----------|
| `devcontainer.json` | Container settings (Node.js 20, VS Code extensions, volumes, etc.) |
| `Dockerfile` | Image definition (Claude Code CLI, zsh, git-delta, etc.) |
| `init-firewall.sh` | Firewall setup at startup (allowlist based) |

## Updating

```bash
cd ~/.devcontainer  # or this directory
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/devcontainer.json
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/Dockerfile
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/init-firewall.sh
```
