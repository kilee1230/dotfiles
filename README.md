# dotfiles

Opinionated dotfiles managed via symlinks. Includes configs for:

- zsh
- git
- ssh (config only; keys are not tracked)
- tmux
- nvim
- kitty
- fish

## Requirements

- macOS or Linux with Bash
- Git

## One-time setup

Clone to `~/.dotfiles` and run adoption + linking. This moves existing configs into the repo (safe), then symlinks back.

```bash
# from anywhere
make adopt
```

You can preview the actions first:

```bash
make dry-run
```

## Common commands

```bash
make install      # Create/update symlinks from repo to $HOME
make adopt        # Move existing configs into repo, then link
make dry-run      # Preview adopt + link without changes
make relink       # Remove existing symlinks and re-link
make clean-backups# Delete created backup files (*.bak.*)
```

## Script details

- `install.sh` is idempotent and supports:
  - `--adopt`: move existing configs from `$HOME` into this repo
  - `--dry-run`: print planned actions only
  - `--no-backup`: disable backup creation
- Existing non-symlink files are backed up as `*.bak.YYYYMMDDHHMMSS` before being replaced.
- SSH: only `~/.ssh/config` is managed. Private keys are not touched or tracked.

## Layout

- `zsh/.*` -> `~/.{zshrc,zshenv,zprofile}`
- `git/.*` -> `~/.{gitconfig,gitignore,gitattributes}`
- `tmux/.tmux.conf` -> `~/.tmux.conf`
- `tmux/.config/tmux/**` -> `~/.config/tmux/**`
- `nvim/.config/nvim/**` -> `~/.config/nvim/**`
- `kitty/.config/kitty/**` -> `~/.config/kitty/**`
- `fish/.config/fish/**` -> `~/.config/fish/**`

## Tips

- Keep secrets (SSH keys, tokens) out of this repo.
- After changing configs in `$HOME`, run `make adopt` to bring them back into the repo.
- After editing files inside this repo, run `make install` to re-link to `$HOME`.
