# dotfiles

Personal agent and engineering configuration.

## Files

- `AGENTS.md` - common agent instructions across all scenarios. This is the source of truth.
- `CLAUDE.md` - a symlink to `AGENTS.md` so Claude Code and other tools read the same content.
- `OPINIONS.md` - durable engineering, product, and career viewpoints.
- `STACK.md` - default tech stack and tooling.
- `config/waybar/` - waybar status bar config (Omarchy), including the Claude/Codex usage-limit module (`scripts/ai-usage.sh`).

## Install

This repo uses a clone-and-symlink model.
Keep the repo cloned anywhere and run `install.sh`; it symlinks the files into `$HOME`.
After that, editing a file or running `git pull` updates every machine in place.

The script is idempotent and non-destructive.
Re-running it is a no-op for already-correct links, and any real file it would replace is moved to a timestamped `.bak` first.

### macOS

```sh
# Prerequisite: git (ships with Xcode CLT) and the GitHub CLI for the private clone
xcode-select --install 2>/dev/null || true
brew install gh && gh auth login   # skip if gh is already authenticated

gh repo clone jyooi/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

### Arch Linux (Omarchy)

```sh
# Prerequisite: git and the GitHub CLI for the private clone
sudo pacman -S --needed git github-cli
gh auth login                      # skip if gh is already authenticated

gh repo clone jyooi/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

If you use SSH keys instead of the GitHub CLI, replace the clone with:

```sh
git clone git@github.com:jyooi/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
```

### What it links

| Link | Target |
| --- | --- |
| `~/AGENTS.md` | `~/dotfiles/AGENTS.md` |
| `~/OPINIONS.md` | `~/dotfiles/OPINIONS.md` |
| `~/STACK.md` | `~/dotfiles/STACK.md` |
| `~/.claude/CLAUDE.md` | `~/dotfiles/AGENTS.md` |
| `~/.config/waybar/config.jsonc` (Linux only) | `~/dotfiles/config/waybar/config.jsonc` |
| `~/.config/waybar/style.css` (Linux only) | `~/dotfiles/config/waybar/style.css` |
| `~/.config/waybar/scripts/ai-usage.sh` (Linux only) | `~/dotfiles/config/waybar/scripts/ai-usage.sh` |

## Local setup

Claude Code reads `~/.claude/CLAUDE.md`, which the install script points at `AGENTS.md` so both names stay in sync from one file.
