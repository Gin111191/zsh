---
name: caffeinate
description: Bật/tắt caffeinate để giữ máy Mac không ngủ, hỗ trợ hẹn giờ bật hoặc tắt sau một khoảng thời gian (kể cả hẹn máy tự sleep). Dùng khi người dùng nói "bật/tắt caffeinate", "giữ máy không ngủ", "hẹn giờ tắt caffeinate", "hẹn giờ sleep máy".
---

# /caffeinate — Giữ máy Mac không ngủ, có hẹn giờ

Dùng script `caffeinate.sh` cùng thư mục cho MỌI thao tác. Script tự chạy tiến trình
tách khỏi phiên chat bằng `nohup` + `disown`, nên KHÔNG bị dọn dẹp khi phiên/job Claude
Code rotate. **KHÔNG** tự chạy `caffeinate -dims` qua Bash tool với `run_in_background:
true` — tiến trình con kiểu đó từng bị hệ thống kill giữa chừng (xác nhận qua
`pmset -g log | grep ClientDied`), khiến máy vẫn ngủ dù tưởng đã bật.

## Chạy
```bash
bash "$HOME/.claude/skills/caffeinate/caffeinate.sh" <lệnh> [tham số]
```

| Lệnh | Ý nghĩa |
|---|---|
| `on` | Bật ngay, giữ máy không ngủ tới khi tắt |
| `on --for <giây>` | Bật ngay + TỰ TẮT sau N giây (pattern hay dùng nhất) |
| `off` | Tắt ngay |
| `off --after <giây>` | Hẹn TẮT sau N giây (không đổi gì ngay bây giờ) |
| `sleep --after <giây>` | Hẹn tắt caffeinate rồi cho máy NGỦ THẬT (`pmset sleepnow`) sau N giây |
| `cancel` | Hủy lịch hẹn đang chờ (nếu có) |
| `status` | Xem caffeinate có đang chạy + có lịch hẹn nào đang chờ không |

Luôn đổi phút/giờ người dùng nói ra **giây** trước khi gọi (vd "90 phút" → 5400, "1 tiếng" → 3600).

## Ví dụ ánh xạ câu nói → lệnh
- "bật caffeinate" → `on`
- "tắt caffeinate" → `off`
- "hẹn giờ sleep máy trong 1h30" → `sleep --after 5400`
- "bật caffeinate, hẹn tắt sau 1 tiếng" → `on --for 3600`
- "hủy lịch hẹn vừa đặt" → `cancel`

## Sau khi chạy
- Đọc output của script — nó tự in giờ dự kiến (tính bằng `date -v+Ns`) khi có hẹn giờ.
- Xác nhận lại với người dùng bằng tiếng Việt: đã bật/tắt gì, giờ dự kiến nếu có hẹn.

## Lưu ý
- `off` (và bước tắt trong `on --for` / `sleep --after`) dùng `killall caffeinate`, sẽ tắt
  CẢ những tiến trình `caffeinate` ngắn hạn do app khác tạo (vd `caffeinate -i -t 300` từ
  Handoff/audio) — vô hại, chúng vốn tự hết hạn.
- Script tự tránh bật trùng: nếu `caffeinate -dims` đã chạy, `on` sẽ báo thay vì bật thêm.
- Chỉ theo dõi **1 lịch hẹn** tại một thời điểm (PID lưu ở
  `~/.claude/skills/caffeinate/schedule.pid`) — đặt lịch mới sẽ tự hủy lịch cũ.
