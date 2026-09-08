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
fi

# Ngoài tmux: để trống thì zvm_clipboard_detect tự dò pbcopy / wl-copy / xclip.
#
# WSL: bốn thứ plugin dò (pbcopy, wl-copy, xclip, xsel) mặc định KHÔNG có cái nào,
# và nó đòi phải set được CẢ copy lẫn paste mới coi clipboard là dùng được — nên
# ngoài tmux là mất hẳn. clip.exe tuy có sẵn nhưng plugin không dò tới. Cách gọn
# nhất là cài wl-clipboard: WSLg đồng bộ hai chiều với clipboard Windows, plugin
# tự nhận ra wl-copy/wl-paste, không cần thêm dòng config nào.
#     sudo apt install wl-clipboard
# Không chọn đường clip.exe + powershell Get-Clipboard: đo trên GIN-PC là 212ms
# mỗi lần dán (tmux 5ms) — đủ chậm để thấy khựng ở từng phím p.

# GIỚI HẠN ĐÃ BIẾT
#   - `yy` mất ký tự xuống dòng cuối: $( ) của shell cắt trailing newline.
#     Trên dòng lệnh thì thường là điều mình muốn.
#   - OSC 52 chỉ MỘT CHIỀU (ghi). Copy từ trình duyệt rồi `p` trong shell sẽ
#     không ra nội dung đó — chỗ đó vẫn phải Cmd+V / Ctrl+Shift+V.
#   - Cần `set -g set-clipboard on` bên tmux thì OSC 52 mới đi được.
#     tmux-config (github.com/Gin111191/tmux-config) đã bật sẵn.
