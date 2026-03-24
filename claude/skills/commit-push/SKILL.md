---
name: commit-push
description: Commit all changes and push to remote. Use when user says "コミットしてpush", "commit and push", "/commit-push", or any short phrase asking to stage, commit, and push changes.
allowed-tools: Bash(git status), Bash(git diff), Bash(git log), Bash(git add), Bash(git commit), Bash(git push)
---

# Current changes
!`git status --short`

# Diff
!`git diff HEAD`

# Recent commits (for message style)
!`git log --oneline -5`

---

Based on the above:

1. Stage all modified/new files relevant to the changes (prefer specific file names over `git add .` to avoid including secrets or large binaries — but if the changes are clearly safe and broad, `git add -A` is fine). **Important:** paths containing `[` or `]` (e.g. `src/app/[locale]/`) must be single-quoted to prevent zsh glob expansion: `git add 'src/app/[locale]/layout.tsx'`
2. Write a concise commit message following the style of recent commits (e.g. `feat:`, `fix:`, `chore:`)
3. Commit using a HEREDOC so the message formats correctly:
   ```
   git commit -m "$(cat <<'EOF'
   <message>

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```
4. Push: `git push origin <current-branch>`
5. Confirm success with a one-line summary of what was committed

If there is nothing to commit, say so briefly.
