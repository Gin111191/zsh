# ~/.config/zsh/.zshenv

# ---------- Global compinit ----------
# Ubuntu's /etc/zsh/zshrc runs its own compinit before .zshrc gets a say, which
# dumps a second cache into $ZDOTDIR and costs a redundant scan every startup.
# .zshrc:56 does the real one, into $XDG_CACHE_HOME/zsh/zcompdump.
skip_global_compinit=1

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- Starship ----------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"

# ---------- WSL: Windows clipboard ----------
# Interop appends the Windows PATH, then the login session is handed the fixed
# PATH out of /etc/environment and it is gone again. clipboard.zsh gates its
# clip.exe branch on $commands, so without this the Ctrl+V-into-Windows half of
# a yank dies silently. One directory, not the whole Windows PATH.
#
# The test is the binary itself, NOT $WSL_DISTRO_NAME: the same login session
# that loses the Windows PATH also loses WSL_DISTRO_NAME, DISPLAY and
# WAYLAND_DISPLAY, so every WSL probe written against that variable is false on
# the one machine it was meant for. No clip.exe, no Windows to speak of.
[[ -x /mnt/c/Windows/System32/clip.exe ]] && path+=(/mnt/c/Windows/System32)
