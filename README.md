# dotfiles

Personal agent and engineering configuration.

## Files

- `AGENTS.md` - common agent instructions across all scenarios. This is the source of truth.
- `CLAUDE.md` - a symlink to `AGENTS.md` so Claude Code and other tools read the same content.
- `OPINIONS.md` - durable engineering, product, and career viewpoints.
- `STACK.md` - default tech stack and tooling.

## Local setup

Claude Code reads `~/.claude/CLAUDE.md`.
Locally that path is a symlink to `~/AGENTS.md`, which keeps both names in sync from one file.
