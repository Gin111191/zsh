# =========================================================
# Keybindings
# =========================================================

# Cursor shape per vi mode
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# zsh-vi-mode resets all bindings on init, so custom bindings must be
# registered after it loads. plugins.zsh calls this from zvm_after_init;
# defining zvm_after_init here too would be silently overwritten.
_my_bindings() {
  # Ctrl+Right -> move forward one word (^[[1;5C is the terminal escape code)
  bindkey '^[[1;5C' forward-word

  # Ctrl+Left -> move backward one word (^[[1;5D is the terminal escape code)
  bindkey '^[[1;5D' backward-word

  # Ctrl+F -> fzf file picker (no hidden files)
  bindkey '^F' _fzf_file_no_hidden

  # Ctrl+\ -> toggle autosuggestions (useful for screen recordings)
  bindkey '^\' autosuggest-toggle

  # Up/Down -> history search by substring (^[[A/^[[B are up/down arrow escape codes)
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down

  # p/P -> paste from the SHARED store (see clipboard.zsh), not this zsh process's
  # own $CUTBUFFER. By default the plugin has p/P read CUTBUFFER and only gp/gP
  # read the clipboard — copying vim ("+p). Here it is the other way round: p is
  # the key used every day.
  # p/P live in the vicmd keymap, so they must be bound later — see
  # _my_vicmd_bindings.
  _my_vicmd_bindings
}

# Bind p/P in the vicmd keymap.
#
# Two traps sit on top of each other, and either one makes the binding vanish
# without a word:
#
#  1. zvm_bindkey CANNOT be used here. While lazy keybindings are on (the
#     default), it just files every keymap other than viins into
#     ZVM_LAZY_KEYBINDINGS_LIST and returns. That list is processed before
#     zvm_after_init runs, so p/P never get bound at all. (^F above still works
#     because it attaches to viins.)
#
#  2. But a plain bindkey inside zvm_after_init is not enough either: the FIRST
#     time you press Esc, zvm applies the lazy list with `eval "zvm_bindkey ..."`
#     for the vicmd keymap too — overwriting the binding just made. Check with
#     bindkey right after opening a shell and it looks right; press Esc once and
#     it is back to vi-put-after.
#
# So it has to be bound again in the after_lazy_keybindings hook, which is where
# zvm runs RIGHT AFTER finishing with the lazy list. Still called from
# _my_bindings as well, in case someone turns ZVM_LAZY_KEYBINDINGS off — then
# this hook never runs.
_my_vicmd_bindings() {
  zvm_define_widget _zvm_put_shared_after
  zvm_define_widget _zvm_put_shared_before
  bindkey -M vicmd  'p' _zvm_put_shared_after
  bindkey -M vicmd  'P' _zvm_put_shared_before
  bindkey -M visual 'p' zvm_visual_paste_clipboard
}

zvm_after_lazy_keybindings() {
  _my_vicmd_bindings
}

# Paste from the shared store, with a fallback. The plugin's
# zvm_paste_clipboard_after just `return`s when the clipboard is empty — pressing
# p then feels like a dead key. This version falls back to CUTBUFFER.
_zvm_put_shared() {   # $1 = after | before
  local content saved
  content=$(zvm_clipboard_get)
  if [[ -n $content ]]; then
    saved=$CUTBUFFER
    CUTBUFFER=$content
    [[ $1 == after ]] && zvm_vi_put_after || zvm_vi_put_before
    CUTBUFFER=$saved
  else
    [[ $1 == after ]] && zvm_vi_put_after || zvm_vi_put_before
  fi
}
_zvm_put_shared_after()  { _zvm_put_shared after }
_zvm_put_shared_before() { _zvm_put_shared before }
