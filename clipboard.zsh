# =========================================================
# Clipboard dùng chung — MỘT kho duy nhất cho mọi nơi
# =========================================================
#
# VẤN ĐỀ: zsh-vi-mode yank vào $CUTBUFFER, mà đó là biến nằm TRONG tiến trình
# zsh. Mỗi pane tmux là một zsh riêng => mỗi pane một kho, `p` ở hai pane ra
# hai giá trị khác nhau.
#
# CÁCH GIẢI: lấy buffer của tmux làm kho duy nhất. Nó vốn dùng chung cho mọi
# pane, và cờ -w bảo tmux đẩy tiếp qua OSC 52 về clipboard của máy đang ngồi.
# Một lần yank nằm ở cả hai chỗ, kể cả khi đang SSH.
#
# Nhánh tmux KHÔNG phụ thuộc hệ điều hành: macOS, Linux qua SSH và WSL dùng
# chung đúng đoạn này — không cần clip.exe, xclip hay dò OS.
#
# Đo trên tmux 3.7: đọc 3.8ms/lần (nhanh gấp đôi pbpaste 7.9ms). tmux nói
# chuyện qua unix socket NỘI MÁY nên SSH cũng không phát sinh vòng mạng.

ZVM_SYSTEM_CLIPBOARD_ENABLED=true

if [[ -n $TMUX ]]; then
  ZVM_CLIPBOARD_PASTE_CMD='tmux save-buffer -'

  # Cờ -w chỉ có từ tmux 3.2. Dò một lần lúc mở shell thay vì so chuỗi phiên
  # bản — mọi kiểu so chuỗi đều vỡ khi gặp 3.10.
  if printf '' | tmux load-buffer -w -b _zvm_probe - 2>/dev/null; then
    ZVM_CLIPBOARD_COPY_CMD='tmux load-buffer -w -'
  else
    ZVM_CLIPBOARD_COPY_CMD='tmux load-buffer -'
  fi
  tmux delete-buffer -b _zvm_probe 2>/dev/null

  # WSL: cờ -w chỉ bảo tmux PHÁT OSC 52 — terminal phải cài đặt nó mới có tác
  # dụng. conhost (console cũ của Windows) thì không: đã bắn thẳng escape
  # \033]52 vào tty của client, bỏ qua tmux, clipboard Windows vẫn không đổi.
  # Phía tmux đã đúng hết (set-clipboard on, terminal-features xterm*:clipboard,
  # capability Ms có mặt), lỗi nằm ở đầu nhận.
  #
  # Ghi song song hai nơi: tmux buffer lo `p` giữa các pane (5ms), clip.exe lo
  # Ctrl+V trong app Windows (37ms). clip.exe nuốt đúng UTF-8 tiếng Việt có dấu
  # và văn bản nhiều dòng.
  if [[ -n $WSL_DISTRO_NAME ]] && (( $+commands[clip.exe] )); then
    _zvm_wsl_copy() {
      local buf=$(cat)
      print -rn -- "$buf" | tmux load-buffer -w -
      print -rn -- "$buf" | clip.exe
    }
    ZVM_CLIPBOARD_COPY_CMD='_zvm_wsl_copy'
  fi
fi

# Ngoài tmux: để trống thì zvm_clipboard_detect tự dò pbcopy / wl-copy / xclip.

# GIỚI HẠN ĐÃ BIẾT
#   - `yy` mất ký tự xuống dòng cuối: $( ) của shell cắt trailing newline.
#     Trên dòng lệnh thì thường là điều mình muốn.
#   - Chiều Windows -> shell KHÔNG đi qua `p`. Trong tmux, `p` đọc tmux buffer
#     chứ không đọc clipboard Windows. Copy từ trình duyệt rồi dán vào shell thì
#     dùng chuột phải / Ctrl+Shift+V của terminal (đã chạy sẵn, không cần config).
#     Không bắt `p` đọc clipboard Windows vì powershell Get-Clipboard mất 212ms.
#   - Cần `set -g set-clipboard on` bên tmux thì OSC 52 mới đi được.
#     tmux-config (github.com/Gin111191/tmux-config) đã bật sẵn.
