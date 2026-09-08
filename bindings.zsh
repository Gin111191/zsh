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
  # p/P nằm ở keymap vicmd nên phải gán muộn hơn, xem _my_vicmd_bindings.
  _my_vicmd_bindings
}

# Gán p/P cho keymap vicmd.
#
# Hai cái bẫy chồng nhau, cái nào cũng làm binding im lặng biến mất:
#
#  1. zvm_bindkey KHÔNG dùng được ở đây. Khi lazy keybindings còn bật (mặc định
#     true), nó chỉ xếp mọi keymap != viins vào ZVM_LAZY_KEYBINDINGS_LIST rồi
#     return. Danh sách đó xử lý xong trước khi zvm_after_init chạy, nên p/P
#     không bao giờ được gán. (^F ở trên vẫn chạy vì nó gắn vào viins.)
#
#  2. Nhưng bindkey thường trong zvm_after_init cũng chưa đủ: lần ĐẦU bấm Esc,
#     zvm mới áp dụng danh sách lazy bằng `eval "zvm_bindkey ..."` cho cả keymap
#     vicmd — đè mất binding vừa gán. Kiểm tra bằng bindkey ngay sau khi mở shell
#     thì thấy đúng, bấm Esc một cái là về lại vi-put-after.
#
# Nên phải gán lại trong hook after_lazy_keybindings, là chỗ zvm chạy NGAY SAU
# khi áp dụng xong danh sách lazy. Vẫn gọi trong _my_bindings để phòng trường hợp
# ai đó tắt ZVM_LAZY_KEYBINDINGS — khi ấy hook này không bao giờ chạy.
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
