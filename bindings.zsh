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

  # p/P -> dán từ kho DÙNG CHUNG (xem clipboard.zsh), không phải $CUTBUFFER riêng
  # của tiến trình zsh này. Mặc định plugin để p/P đọc CUTBUFFER và chỉ gp/gP mới
  # đọc clipboard — bắt chước vim ("+p). Ở đây đảo lại: p là phím dùng hằng ngày.
  zvm_define_widget _zvm_put_shared_after
  zvm_define_widget _zvm_put_shared_before
  zvm_bindkey vicmd  'p' _zvm_put_shared_after
  zvm_bindkey vicmd  'P' _zvm_put_shared_before
  zvm_bindkey visual 'p' zvm_visual_paste_clipboard
}

# Dán kho chung, có đường lui. zvm_paste_clipboard_after của plugin `return`
# ngay khi clipboard rỗng — bấm p thấy như phím chết. Bản này rơi về CUTBUFFER.
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
