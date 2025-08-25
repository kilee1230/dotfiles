# dotfiles

Opinionated dotfiles managed via symlinks. Includes configs for:

- zsh
- git
- ssh (config only; keys are not tracked)
- tmux
- nvim
- kitty
- fish
- aws (config only; credentials are not tracked)
  - amazonq subdirectory (non-secret files only)
- VS Code (macOS User settings)
- Cursor (macOS User settings)
- GnuPG (config only; keys are not tracked)

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
make install       # Create/update symlinks from repo to $HOME
make adopt         # Move existing configs into repo, then link
make dry-run       # Preview adopt + link without changes
make relink        # Remove existing symlinks and re-link
make clean-backups # Delete created backup files (*.bak.*)
make backup-gnupg  # Tar.gz backup of ~/.gnupg (do not commit)
make brew-bundle   # Install Homebrew packages from ~/.Brewfile
make brew-dump     # Export current Homebrew packages to brew/Brewfile
```

## macOS migration steps (new machine)

1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Add brew to PATH (follow on-screen instructions), e.g. for zsh:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
```

3. Clone dotfiles and link configs

```bash
git clone git@github.com:<your-username>/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make install        # or make adopt if preexisting configs exist
```

4. Install apps via Brewfile

```bash
make brew-bundle    # uses ~/.Brewfile (symlinked from repo if present)
```

5. Restore editors and shells

- VS Code and Cursor settings are linked automatically
- Open VS Code, sign in to extensions sync if you use it
- Start a new terminal session to load zsh config

6. AWS, SSH, and GnuPG

- SSH: add your private keys into `~/.ssh` manually if needed; keys are not tracked
- AWS: `~/.aws/config` and `amazonq/` are linked; put credentials back into `~/.aws/credentials`
- GnuPG: configs are linked; import keys if needed and verify permissions

7. Optional: export current brew state back to repo

```bash
make brew-dump
```

## Script details

- `install.sh` is idempotent and supports:
  - `--adopt`: move existing configs from `$HOME` into this repo
  - `--dry-run`: print planned actions only
  - `--no-backup`: disable backup creation
- Existing non-symlink files are backed up as `*.bak.YYYYMMDDHHMMSS` before being replaced.
- SSH: only `~/.ssh/config` is managed. Private keys are not touched or tracked.
- AWS: only `~/.aws/config` and `~/.aws/amazonq/**` are managed. `~/.aws/credentials` is never adopted or linked.
- VS Code/Cursor: User-level settings are managed (macOS paths above).
- GnuPG: only `gpg.conf`, `gpg-agent.conf`, and `dirmngr.conf` are managed. Keys and keyrings are never tracked.

## Layout

- `zsh/.*` -> `~/.{zshrc,zshenv,zprofile}`
- `git/.*` -> `~/.{gitconfig,gitignore,gitattributes}`
- `tmux/.tmux.conf` -> `~/.tmux.conf`
- `tmux/.config/tmux/**` -> `~/.config/tmux/**`
- `nvim/.config/nvim/**` -> `~/.config/nvim/**`
- `kitty/.config/kitty/**` -> `~/.config/kitty/**`
- `fish/.config/fish/**` -> `~/.config/fish/**`
- `aws/.aws/config` -> `~/.aws/config`
- `aws/.aws/amazonq/**` -> `~/.aws/amazonq/**`
- `vscode/Library Application Support/Code/User/{settings.json,keybindings.json,snippets/**}` -> `~/Library/Application Support/Code/User/...`
- `cursor/Library Application Support/Cursor/User/{settings.json,keybindings.json,snippets/**}` -> `~/Library/Application Support/Cursor/User/...`
- `gnupg/.gnupg/{gpg.conf,gpg-agent.conf,dirmngr.conf}` -> `~/.gnupg/{...}`
- `brew/Brewfile` -> `~/.Brewfile`

## Tips

- Keep secrets (SSH keys, tokens, AWS credentials, GnuPG private keys) out of this repo.
- Use `make backup-gnupg` to archive your full `~/.gnupg` locally before changes.
- After changing configs in `$HOME`, run `make adopt` to bring them back into the repo.
- After editing files inside this repo, run `make install` to re-link to `$HOME`.
