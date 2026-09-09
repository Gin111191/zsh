# ~/.config/zsh/.zprofile
# When ZDOTDIR is set, zsh reads this file INSTEAD OF ~/.zprofile (once, at login).

# ---------- Homebrew ----------
# Probe all three locations: Apple Silicon, Intel Mac, Linuxbrew. The
# HOMEBREW_PREFIX guard stops it running again in a nested login shell (tmux, ssh
# into this same machine) — running it twice puts duplicate entries in PATH.
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$_brew" ]]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi

# ---------- Escape hatch for installers ----------
# ZDOTDIR means zsh no longer reads ~/.zprofile. Plenty of installers (nvm, conda,
# rustup…) still write straight into it, and would silently have no effect. Source
# it back here so they keep working.
[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
