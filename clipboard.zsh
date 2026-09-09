# =========================================================
# Shared clipboard — ONE store for everywhere
# =========================================================
#
# THE PROBLEM: zsh-vi-mode yanks into $CUTBUFFER, and that is a variable living
# INSIDE the zsh process. Every tmux pane is its own zsh => every pane its own
# store, so `p` in two panes gives two different values.
#
# THE FIX: make tmux's buffer the single store. It is already shared across
# every pane, and the -w flag tells tmux to push it on via OSC 52 to the
# clipboard of the machine you are sitting at. One yank lands in both places,
# even over SSH.
#
# The tmux branch does NOT depend on the operating system: macOS, Linux over SSH
# and WSL all use exactly this code — no clip.exe, no xclip, no OS probing.
#
# Measured on tmux 3.7: 3.8ms per read (twice as fast as pbpaste at 7.9ms). tmux
# talks over a LOCAL unix socket, so SSH adds no network round trip either.

ZVM_SYSTEM_CLIPBOARD_ENABLED=true

if [[ -n $TMUX ]]; then
  ZVM_CLIPBOARD_PASTE_CMD='tmux save-buffer -'

  # The -w flag only exists from tmux 3.2 on. Probe once at shell startup rather
  # than comparing version strings — every kind of string compare breaks on 3.10.
  if printf '' | tmux load-buffer -w -b _zvm_probe - 2>/dev/null; then
    ZVM_CLIPBOARD_COPY_CMD='tmux load-buffer -w -'
  else
    ZVM_CLIPBOARD_COPY_CMD='tmux load-buffer -'
  fi
  tmux delete-buffer -b _zvm_probe 2>/dev/null

  # WSL: the -w flag only tells tmux to EMIT OSC 52 — the terminal has to
  # implement it for anything to happen. conhost (the legacy Windows console)
  # does not: firing the escape \033]52 straight at the client's tty, bypassing
  # tmux, still left the Windows clipboard unchanged. Everything on the tmux side
  # is correct (set-clipboard on, terminal-features xterm*:clipboard, the Ms
  # capability present) — the fault is at the receiving end.
  #
  # So write to both places at once: the tmux buffer handles `p` between panes
  # (5ms), clip.exe handles Ctrl+V inside Windows apps (37ms). clip.exe swallows
  # accented Vietnamese UTF-8 and multi-line text correctly.
  if [[ -n $WSL_DISTRO_NAME ]] && (( $+commands[clip.exe] )); then
    _zvm_wsl_copy() {
      local buf=$(cat)
      print -rn -- "$buf" | tmux load-buffer -w -
      print -rn -- "$buf" | clip.exe
    }
    ZVM_CLIPBOARD_COPY_CMD='_zvm_wsl_copy'
  fi
fi

# Outside tmux: leave these empty and zvm_clipboard_detect finds pbcopy /
# wl-copy / xclip by itself.

# KNOWN LIMITS
#   - `yy` loses the trailing newline: the shell's $( ) strips it. On a command
#     line that is usually what you want anyway.
#   - The Windows -> shell direction does NOT go through `p`. Inside tmux, `p`
#     reads the tmux buffer, not the Windows clipboard. To paste something copied
#     from a browser into the shell, use the terminal's own right-click /
#     Ctrl+Shift+V (works already, needs no config). `p` is deliberately not
#     wired to the Windows clipboard because powershell Get-Clipboard costs 212ms.
#   - tmux needs `set -g set-clipboard on` for OSC 52 to get out at all.
#     tmux-config (github.com/Gin111191/tmux-config) already turns it on.
