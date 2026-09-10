---
name: zalo-send
description: Gửi bất kỳ file local nào vào Zalo Web (mặc định hội thoại "My Documents") để xem/tải trên điện thoại. File .html sẽ tự render PDF trước. Dùng khi người dùng nói "gửi file này lên zalo / vào my documents / để xem trên điện thoại".
---

# /zalo-send — Gửi file vào Zalo (xem trên điện thoại)

Gửi 1+ file vào 1 hội thoại Zalo Web qua Chrome đang chạy debug. Tất cả công thức
đã-chạy-được nằm trong script `send.py` cùng thư mục → **lần sau chỉ 1 lệnh, ~15–20s**.

## Chạy
```bash
python3 "$HOME/.claude/skills/zalo-send/send.py" <file1> [file2 ...] [--to "My Documents"]
```
- Gửi **bất kỳ loại file** (pdf, png, xlsx, docx, zip…). Nhiều file: liệt kê cách nhau bởi dấu cách.
- File **.html** mặc định **render sang PDF** trước (HTML xem trên đt rất xấu). Tắt: `--no-render-html`.
- `--to` = tên hội thoại đích (mặc định "My Documents"). Script **xác minh header == --to**, lệch → ABORT (không gửi nhầm người).
- `--dry-run` = mở hội thoại + kiểm nút đính kèm, KHÔNG gửi (để thử an toàn).
- Báo `✅ Đã gửi …` khi xác minh thấy file trong hội thoại; lỗi thì exit ≠ 0 và nói rõ.

## Tiền đề (script tự kiểm; nếu thiếu sẽ báo cách khắc phục)
1. **playwright** (python, user-site) — đã cài global cho mọi project. Thiếu: `python3 -m pip install --user playwright`.
2. **Chrome debug cổng 9222** trên profile KHÔNG mặc định, **đã đăng nhập Zalo Web**. Nếu chưa sống, bật:
   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --remote-debugging-port=9222 --user-data-dir="$HOME/.cache/claude-chrome-min" &
   ```
   Lần đầu: mở chat.zalo.me quét QR (session lưu lại trong profile cho lần sau). KHÔNG dùng profile Chrome mặc định (Chrome chặn debug ở dir mặc định).

## Lưu ý
- KHÔNG tự bật Chrome bằng profile mặc định của người dùng (tránh đụng phiên họ đang dùng).
- Render HTML→PDF dùng `chrome-headless-shell` của ms-playwright (script tự tìm bản mới nhất). Thiếu: `python3 -m playwright install chromium`.
- Cơ chế Zalo (đã giải mã, đã gói trong script): nút **"Đính kèm File"** mở popup **"Chọn File"** mới bung hộp chọn file; tên hội thoại có nbsp (chuẩn hoá bằng `split()`); gửi bằng Enter; xác minh qua preview hội thoại.
