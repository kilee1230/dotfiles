#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
ADOPT=false
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

log() { echo "[link] $*"; }
warn() { echo "[warn] $*" >&2; }
run() {
	if $DRY_RUN; then
		printf "DRY-RUN: %s\n" "$*"
	else
		eval "$@"
	fi
}

ensure_dir() {
	local dir="$1"
	if [ ! -d "$dir" ]; then
		log "mkdir -p $dir"
		run "mkdir -p \"$dir\""
	fi
}

backup_if_exists() {
	local path="$1"
	if [ -e "$path" ] && [ ! -L "$path" ] && [ -n "$BACKUP_SUFFIX" ]; then
		log "backup $path -> ${path}${BACKUP_SUFFIX}"
		run "mv \"$path\" \"${path}${BACKUP_SUFFIX}\""
	fi
}

link_file() {
	local src="$1"
	local dest="$2"
	ensure_dir "$(dirname "$dest")"
	if [ -L "$dest" ] || [ -e "$dest" ]; then
		# If it's already the correct symlink, skip
		if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
			log "exists (ok): $dest -> $src"
			return
		fi
		backup_if_exists "$dest"
		# Remove existing symlink so we can relink
		if [ -L "$dest" ]; then
			log "rm existing symlink $dest"
			run "rm \"$dest\""
		fi
	fi
	log "ln -s $src $dest"
	run "ln -s \"$src\" \"$dest\""
}

adopt_file() {
	# Move an existing file/dir at $1 into repo at $2 if not already present
	local existing="$1"
	local repo_target="$2"
	if ! $ADOPT; then return; fi
	if [ -e "$existing" ] && [ ! -L "$existing" ]; then
		if [ -e "$repo_target" ]; then
			warn "repo already has $(basename "$repo_target"), skipping adopt for $existing"
			return
		fi
		log "adopt $existing -> $repo_target"
		ensure_dir "$(dirname "$repo_target")"
		run "mv \"$existing\" \"$repo_target\""
	fi
}

# Parse flags
for arg in "$@"; do
	case "$arg" in
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--adopt)
			ADOPT=true
			shift
			;;
		--no-backup)
			BACKUP_SUFFIX=""
			shift
			;;
		*) ;;
	esac
done

HOME_DIR="$HOME"
CONFIG_DIR="$HOME_DIR/.config"
ensure_dir "$CONFIG_DIR"

# Mapping rules: add new ones as needed
# kitty
if [ -d "$REPO_DIR/kitty/.config/kitty" ]; then
	while IFS= read -r -d '' file; do
		rel_path="${file#"$REPO_DIR/kitty/.config/kitty/"}"
		src="$file"
		dest="$CONFIG_DIR/kitty/$rel_path"
		link_file "$src" "$dest"
	done < <(find "$REPO_DIR/kitty/.config/kitty" -type f -print0)
else
	# adopt from user config if present
	if [ -d "$CONFIG_DIR/kitty" ]; then
		adopt_file "$CONFIG_DIR/kitty" "$REPO_DIR/kitty/.config/kitty"
	fi
fi

# nvim
if [ -d "$REPO_DIR/nvim/.config/nvim" ]; then
	while IFS= read -r -d '' file; do
		rel_path="${file#"$REPO_DIR/nvim/.config/nvim/"}"
		src="$file"
		dest="$CONFIG_DIR/nvim/$rel_path"
		link_file "$src" "$dest"
	done < <(find "$REPO_DIR/nvim/.config/nvim" -type f -print0)
else
	if [ -d "$CONFIG_DIR/nvim" ]; then
		adopt_file "$CONFIG_DIR/nvim" "$REPO_DIR/nvim/.config/nvim"
	fi
fi

# fish
if [ -d "$REPO_DIR/fish/.config/fish" ]; then
	while IFS= read -r -d '' file; do
		rel_path="${file#"$REPO_DIR/fish/.config/fish/"}"
		src="$file"
		dest="$CONFIG_DIR/fish/$rel_path"
		link_file "$src" "$dest"
	done < <(find "$REPO_DIR/fish/.config/fish" -type f -print0)
else
	if [ -d "$CONFIG_DIR/fish" ]; then
		adopt_file "$CONFIG_DIR/fish" "$REPO_DIR/fish/.config/fish"
	fi
fi

# zsh: link files from zsh/ to $HOME
if [ -d "$REPO_DIR/zsh" ]; then
	for f in "$REPO_DIR"/zsh/.*; do
		[ -e "$f" ] || continue
		base="$(basename "$f")"
		# Skip . and ..
		[ "$base" = "." ] && continue
		[ "$base" = ".." ] && continue
		link_file "$f" "$HOME_DIR/$base"
	done
fi
# adopt zsh files
adopt_file "$HOME_DIR/.zshrc" "$REPO_DIR/zsh/.zshrc"
adopt_file "$HOME_DIR/.zshenv" "$REPO_DIR/zsh/.zshenv"
adopt_file "$HOME_DIR/.zprofile" "$REPO_DIR/zsh/.zprofile"

# git
if [ -d "$REPO_DIR/git" ]; then
	for f in "$REPO_DIR"/git/.*; do
		[ -e "$f" ] || continue
		base="$(basename "$f")"
		[ "$base" = "." ] && continue
		[ "$base" = ".." ] && continue
		link_file "$f" "$HOME_DIR/$base"
	done
fi
# adopt git files
adopt_file "$HOME_DIR/.gitconfig" "$REPO_DIR/git/.gitconfig"
adopt_file "$HOME_DIR/.gitignore" "$REPO_DIR/git/.gitignore"
adopt_file "$HOME_DIR/.gitattributes" "$REPO_DIR/git/.gitattributes"

# tmux
if [ -d "$REPO_DIR/tmux" ]; then
	# Either ~/.tmux.conf or ~/.config/tmux/
	if [ -f "$REPO_DIR/tmux/.tmux.conf" ]; then
		link_file "$REPO_DIR/tmux/.tmux.conf" "$HOME_DIR/.tmux.conf"
	fi
	if [ -d "$REPO_DIR/tmux/.config/tmux" ]; then
		while IFS= read -r -d '' file; do
			rel_path="${file#"$REPO_DIR/tmux/.config/tmux/"}"
			src="$file"
			dest="$CONFIG_DIR/tmux/$rel_path"
			link_file "$src" "$dest"
		done < <(find "$REPO_DIR/tmux/.config/tmux" -type f -print0)
	fi
fi
# adopt tmux
adopt_file "$HOME_DIR/.tmux.conf" "$REPO_DIR/tmux/.tmux.conf"

# ssh
if [ -d "$REPO_DIR/ssh" ]; then
	ensure_dir "$HOME_DIR/.ssh"
	chmod 700 "$HOME_DIR/.ssh" || true
	for f in "$REPO_DIR"/ssh/*; do
		[ -e "$f" ] || continue
		base="$(basename "$f")"
		link_file "$f" "$HOME_DIR/.ssh/$base"
		# Secure permissions for private keys
		case "$base" in
			id_*|*key)
				if ! $DRY_RUN; then chmod 600 "$HOME_DIR/.ssh/$base" || true; fi
				;;
		esac
	done
fi
# adopt ssh (safe: only adopt config)
adopt_file "$HOME_DIR/.ssh/config" "$REPO_DIR/ssh/config"

# aws (manage config only; never credentials)
if [ -d "$REPO_DIR/aws/.aws" ] || [ -f "$REPO_DIR/aws/.aws/config" ]; then
	ensure_dir "$HOME_DIR/.aws"
	if [ -f "$REPO_DIR/aws/.aws/config" ]; then
		link_file "$REPO_DIR/aws/.aws/config" "$HOME_DIR/.aws/config"
		if ! $DRY_RUN; then chmod 600 "$HOME_DIR/.aws/config" || true; fi
	fi
else
	# adopt from user if present
	if [ -f "$HOME_DIR/.aws/config" ]; then
		adopt_file "$HOME_DIR/.aws/config" "$REPO_DIR/aws/.aws/config"
	fi
fi

# aws amazonq directory
if [ -d "$REPO_DIR/aws/.aws/amazonq" ]; then
	while IFS= read -r -d '' file; do
		rel_path="${file#"$REPO_DIR/aws/.aws/amazonq/"}"
		src="$file"
		dest="$HOME_DIR/.aws/amazonq/$rel_path"
		link_file "$src" "$dest"
	done < <(find "$REPO_DIR/aws/.aws/amazonq" -type f -print0)
else
	if [ -d "$HOME_DIR/.aws/amazonq" ]; then
		adopt_file "$HOME_DIR/.aws/amazonq" "$REPO_DIR/aws/.aws/amazonq"
	fi
fi

# VS Code user settings (macOS)
CODE_USER_DIR="$HOME_DIR/Library/Application Support/Code/User"
REPO_CODE_DIR="$REPO_DIR/vscode/Library Application Support/Code/User"
if [ -d "$REPO_CODE_DIR" ]; then
	ensure_dir "$CODE_USER_DIR"
	if [ -f "$REPO_CODE_DIR/settings.json" ]; then
		link_file "$REPO_CODE_DIR/settings.json" "$CODE_USER_DIR/settings.json"
	fi
	if [ -f "$REPO_CODE_DIR/keybindings.json" ]; then
		link_file "$REPO_CODE_DIR/keybindings.json" "$CODE_USER_DIR/keybindings.json"
	fi
	if [ -d "$REPO_CODE_DIR/snippets" ]; then
		link_file "$REPO_CODE_DIR/snippets" "$CODE_USER_DIR/snippets"
	fi
else
	# adopt from user if present
	if [ -f "$CODE_USER_DIR/settings.json" ]; then
		adopt_file "$CODE_USER_DIR/settings.json" "$REPO_CODE_DIR/settings.json"
	fi
	if [ -f "$CODE_USER_DIR/keybindings.json" ]; then
		adopt_file "$CODE_USER_DIR/keybindings.json" "$REPO_CODE_DIR/keybindings.json"
	fi
	if [ -d "$CODE_USER_DIR/snippets" ]; then
		adopt_file "$CODE_USER_DIR/snippets" "$REPO_CODE_DIR/snippets"
	fi
fi

# Cursor user settings (macOS)
CURSOR_USER_DIR="$HOME_DIR/Library/Application Support/Cursor/User"
REPO_CURSOR_DIR="$REPO_DIR/cursor/Library Application Support/Cursor/User"
if [ -d "$REPO_CURSOR_DIR" ]; then
	ensure_dir "$CURSOR_USER_DIR"
	if [ -f "$REPO_CURSOR_DIR/settings.json" ]; then
		link_file "$REPO_CURSOR_DIR/settings.json" "$CURSOR_USER_DIR/settings.json"
	fi
	if [ -f "$REPO_CURSOR_DIR/keybindings.json" ]; then
		link_file "$REPO_CURSOR_DIR/keybindings.json" "$CURSOR_USER_DIR/keybindings.json"
	fi
	if [ -d "$REPO_CURSOR_DIR/snippets" ]; then
		link_file "$REPO_CURSOR_DIR/snippets" "$CURSOR_USER_DIR/snippets"
	fi
else
	# adopt from user if present
	if [ -f "$CURSOR_USER_DIR/settings.json" ]; then
		adopt_file "$CURSOR_USER_DIR/settings.json" "$REPO_CURSOR_DIR/settings.json"
	fi
	if [ -f "$CURSOR_USER_DIR/keybindings.json" ]; then
		adopt_file "$CURSOR_USER_DIR/keybindings.json" "$REPO_CURSOR_DIR/keybindings.json"
	fi
	if [ -d "$CURSOR_USER_DIR/snippets" ]; then
		adopt_file "$CURSOR_USER_DIR/snippets" "$REPO_CURSOR_DIR/snippets"
	fi
fi

# GnuPG configs (config only; never keys)
GNUPG_HOME="$HOME_DIR/.gnupg"
REPO_GNUPG_DIR="$REPO_DIR/gnupg/.gnupg"
ensure_dir "$GNUPG_HOME"
if ! $DRY_RUN; then chmod 700 "$GNUPG_HOME" || true; fi
if [ -d "$REPO_GNUPG_DIR" ]; then
	for f in gpg.conf gpg-agent.conf dirmngr.conf; do
		if [ -f "$REPO_GNUPG_DIR/$f" ]; then
			link_file "$REPO_GNUPG_DIR/$f" "$GNUPG_HOME/$f"
			if ! $DRY_RUN; then chmod 600 "$GNUPG_HOME/$f" || true; fi
		fi
	done
else
	for f in gpg.conf gpg-agent.conf dirmngr.conf; do
		if [ -f "$GNUPG_HOME/$f" ]; then
			adopt_file "$GNUPG_HOME/$f" "$REPO_GNUPG_DIR/$f"
		fi
	done
fi

# Homebrew Brewfile mapping
REPO_BREWFILE="$REPO_DIR/brew/Brewfile"
if [ -f "$REPO_BREWFILE" ]; then
	link_file "$REPO_BREWFILE" "$HOME_DIR/.Brewfile"
else
	if [ -f "$HOME_DIR/.Brewfile" ]; then
		adopt_file "$HOME_DIR/.Brewfile" "$REPO_BREWFILE"
	fi
fi

log "Done." 