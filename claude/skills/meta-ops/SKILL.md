---
name: meta-ops
description: Thao tác Meta (Facebook Page, Business Manager/portfolio, Ads Manager, đăng avatar/ảnh bìa, upload ảnh, dò UI) qua Chrome đang chạy debug (CDP 9222) bằng playwright + phiên đăng nhập sẵn của user. Dùng khi người dùng nói "tạo page / lập fanpage / tạo business manager / đăng ảnh đại diện / ảnh bìa / chạy/ tạo quảng cáo Facebook / thao tác trên Meta". Đã gói công thức chạy-được → lần sau nhanh, không dò lại.
---

# /meta-ops — Thao tác Meta qua Chrome (CDP 9222)

Lái Facebook/Business/Ads bằng **phiên Chrome đăng nhập sẵn của user** (không tự nhập mật khẩu →
giảm rủi ro bị Meta gắn cờ). Công thức đã-chạy nằm trong `meta_cdp.py` cùng thư mục → lần sau gọi 1 lệnh.

> ⚠️ Thao tác trên tài khoản Facebook THẬT của user = khó đảo + chạy thật. Việc khó đảo (tạo page/BM, đăng ảnh,
> chạy ads tốn tiền) → **báo + duyệt trước**. Ảnh đăng lên trang public nên **render preview → gửi user duyệt → mới đăng**.

## Tiền đề (kiểm trước khi chạy)
1. **Chrome debug cổng 9222, đã đăng nhập Facebook.** Kiểm: `curl -s http://localhost:9222/json/version`.
   Chưa sống thì bật (KHÔNG dùng profile mặc định):
   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --remote-debugging-port=9222 --user-data-dir="$HOME/.cache/claude-chrome-min" &
   ```
   Lần đầu mở facebook.com đăng nhập (phiên lưu trong profile cho lần sau).
2. **playwright python** (user-site): `python3 -c "import playwright"`. Thiếu: `python3 -m pip install --user playwright`.

## Lệnh nhanh (đã test)
```bash
S="$HOME/.claude/skills/meta-ops/meta_cdp.py"
python3 "$S" inspect [--url URL] [--out shot.png]     # chụp + liệt kê nút/menu/input — DÙNG ĐỂ DÒ UI lạ
python3 "$S" render <html> <out.png> <w> <h>          # render HTML → PNG (avatar/cover/card phòng) qua chính Chrome
python3 "$S" page-id "<Tên Page>"                     # lấy Page ID
python3 "$S" create-page --name "..." --category "Công ty bất động sản" [--bio "..."]
python3 "$S" set-avatar --page-id <ID> --img avatar.png   # tự "dùng tư cách Trang" rồi đăng
python3 "$S" set-cover  --page-id <ID> --img cover.png
```
Hàm trong `meta_cdp.py` (import để ghép việc mới): `attach · get_tab · click_text · click_dialog_btn ·
fill_label · set_file_input · upload_via_chooser · dump · ensure_acting_as_page · render_html ·
get_page_id · create_page · set_avatar · set_cover`.

## Phương pháp cho việc MỚI (chưa có hàm sẵn) — vòng lặp dò UI
FB DOM bị rối + đổi liên tục → **đừng click mò**. Làm: `inspect` (hoặc `dump(pg)`) → đọc ảnh + danh sách nút →
click đúng nút theo TEXT (`click_text`) → `inspect` lại → lặp. Lưu mỗi screenshot ra scratchpad rồi Read.
Khi xong việc mới → **thêm hàm vào `meta_cdp.py`** để lần sau nhanh.

## 🚨 RỦI RO LỚN NHẤT — tự động hoá mức DOANH NGHIỆP/ADS bị Meta gắn cờ (2026-06-27, đã dính)
Tạo **Business Manager/portfolio bằng Playwright** → Meta gắn cờ **"Tính toàn vẹn tài khoản"** → portfolio bị **hạn chế quảng cáo + claim app** ("created/used by automated methods"). Mức **Trang** (tạo Page, đăng avatar/bìa) thì QUA được; mức **doanh nghiệp/quảng cáo/app** bị soi chặt → **ĐỪNG tự động hoá**.
- **Quy tắc:** thao tác **Page** (tạo page, avatar, bìa, đăng bài 1 lần) = tự động OK. Thao tác **Business Manager / Ads Manager / tạo & claim App / kháng nghị** = **để USER làm TAY** (hoặc dùng **Graph API chính thức** có token — server-to-server, hợp lệ).
- **Engine đăng bài định kỳ:** DÙNG **Graph API (token)**, KHÔNG điều khiển trình duyệt facebook.com (sẽ bị gắn cờ liêm chính).
- Nếu đã dính hạn chế: user vào Trung tâm hỗ trợ DN → "Vấn đề chưa giải quyết" → **"Yêu cầu xem xét lại"** (bấm TAY).

## GOTCHA (đã trả giá — nhớ kỹ)
- **Viewport KHÔNG bền qua mỗi lần chạy script CDP** → `get_tab` luôn `set_viewport_size` lại. Toạ độ chuột chỉ tin
  được TRONG cùng 1 script đã set viewport; ưu tiên `click_text`/selector hơn toạ độ.
- **Ảnh chụp về theo kích thước cửa sổ Chrome thật** (có thể ~840px dù set 1280) → đọc nội dung, đừng tính px tuyệt đối.
- **Sửa avatar/ảnh bìa Page:** PHẢI "Dùng Facebook với tư cách Trang" trước (nút **"Chuyển ngay" → "Dùng Trang"**;
  `ensure_acting_as_page` lo). Chế độ "Quản lý trang" KHÔNG có nút camera. Xong nhớ user có thể đổi lại cá nhân ở avatar góc phải.
- **Upload 2 kiểu:** (a) input ẩn → `set_file_input`; (b) hộp chọn file hệ thống → `upload_via_chooser` (expect_file_chooser).
  **Ảnh bìa "Tải ảnh lên" = kiểu (b)** — click chay (không expect_file_chooser) sẽ rơi vào **"Tạo bài viết"** (đăng ảnh thành bài) → SAI. Lỡ vào: nhấn **Escape** huỷ (đừng bấm "Tiếp"/đăng).
- **Avatar:** "Thêm ảnh đại diện" → input ẩn → `set_input_files` → dialog "Chọn ảnh đại diện" → **"Lưu"**.
- **Ảnh bìa:** "Thêm ảnh bìa" → menu {Chọn ảnh bìa | Tải ảnh lên} → "Tải ảnh lên" (chooser) → dialog định vị → **"Lưu thay đổi"**.
- **Tạo Page:** 1 cú "Tạo Trang" có thể ĐÃ tạo dù URL không đổi; bấm lại → lỗi "đã quản lý 1 Trang tên …" = trùng.
  ⇒ Sau khi bấm, **xác minh bằng `page-id`**, đừng bấm lại. Field: `get_by_label("Tên Trang"/"Tiểu sử")`;
  Hạng mục = combobox `aria-label "Hạng mục"`, gõ rồi click `role=option` đúng tên.

## Recipe NHIỀU BƯỚC (chưa gói CLI — làm theo, dùng helper)

### Tạo Business Portfolio (BM) RIÊNG + gắn Page
1. `get_tab(ctx, goto="https://business.facebook.com/")` → đọc `business_id` trong URL (đã có BM sẵn thì hiện cái đang chọn).
2. Mở **bộ chuyển doanh nghiệp** (góc trên-trái, dưới chữ "Meta Business Suite"): click phần tử click-được có Y nhỏ nhất
   chứa tên portfolio hiện tại (vd "The Lighthouse…"). → hiện danh sách portfolio + nút **"Tạo trang quản lý tài sản doanh nghiệp"**.
3. Click nút đó → form: ô tên (placeholder mẫu **"Jasper's Market"**) = `input[placeholder="Jasper's Market"]`;
   `get_by_label("Tên")` (tên) · `get_by_label("Họ")` · `get_by_label("Email doanh nghiệp")`. → **"Tạo"**.
4. Hộp **"thêm tài sản"**: tick `checkbox` của Page → **"Tiếp"** → "thêm người" → **"Tiếp"** → "Xem lại" → **"Xác nhận"**.
5. URL đổi sang `business_id=<MỚI>` = BM mới. Lưu ý: **BM mới thường bị HẠN CHẾ QUẢNG CÁO** ("Bạn không thể dùng hồ sơ
   doanh nghiệp này để quảng cáo") → cần "Xem chi tiết" xin xét duyệt (có thể đòi xác minh danh tính). KHÔNG cản đăng bài/chatbot.

### Tạo App (developers.facebook.com/apps → "Tạo ứng dụng")
- Phải là **Nhà phát triển Meta** trước (đăng nhập cá nhân, KHÔNG ở tư cách Trang → nếu acting-as-page thì /apps đẩy về landing; chuyển về cá nhân qua avatar góc phải → tên người). Đăng ký dev = nút "Bắt đầu" góc phải (KHÔNG phải "Đăng ký" = form newsletter). Có thể KHÔNG đòi SMS nếu account đủ tin cậy.
- Wizard: **Chi tiết** (Tên `get_by_label("Tên ứng dụng")` + email sẵn) → **Trường hợp sử dụng** → **Doanh nghiệp** (chọn portfolio) → Tạo. Có popup "cách mới tạo ứng dụng" → Escape/Đóng.
- ⚠️ **GIỚI HẠN ĐÃ GẶP:** các thẻ radio bước "Trường hợp sử dụng" là **widget tuỳ biến CHỐNG tự động hoá** (Playwright báo "not enabled"; div/role=radio/JS-click/toạ-độ đều khó ăn; state flaky). → **Nhờ user click tay 1 thẻ** ("...nội dung trên Trang Facebook" cho auto-đăng bài) rồi user/CEO bấm Tiếp. Nếu muốn thử lại tự động: dùng keyboard (Tab vào nhóm + Space) hoặc click đúng vòng tròn radio mép phải thẻ — nhưng mặc định cứ nhờ user cho nhanh.

### Lấy App ID/Secret + Page Access Token (Graph API) — engine tự đăng bài
- `developers.facebook.com/apps` → Tạo ứng dụng loại **Doanh nghiệp** → Cài đặt→Cơ bản: App ID + App Secret.
- Graph API Explorer (`developers.facebook.com/tools/explorer`): chọn App + Page, quyền `pages_manage_posts`,
  `pages_read_engagement`, `pages_manage_metadata`, `pages_messaging` → Generate token → đổi dài-hạn ở Access Token
  Debugger → lấy token Page "không hết hạn" qua `GET /me/accounts`. (Có thể cần App Review vài ngày.)
- **BẢO MẬT:** token/secret = mật khẩu → KHÔNG ghi vào file trong repo, KHÔNG in ra log/chat. Đưa user tự lưu (.env ngoài repo / trình quản lý mật khẩu).

### ✅ Engine đăng bài qua Graph API — DÙNG `graph_api.py` (đã chạy thật 2026-06-27)
Cách HỢP LỆ để engine đăng bài định kỳ (KHÔNG điều khiển trình duyệt FB). File `graph_api.py` cùng thư mục, đọc key từ 1 file `.env`, **không in token**:
```bash
G="$HOME/.claude/skills/meta-ops/graph_api.py"; E="duong/dan/.env"
python3 "$G" get-token --env "$E"   # User token tạm (FB_USER_TOKEN_TEMP) -> Page token không hết hạn, ghi .env
python3 "$G" debug    --env "$E"     # in scopes + hạn (kiểm pages_manage_posts)
python3 "$G" post     --env "$E" --message "..."   # đăng -> in post_id
python3 "$G" feed     --env "$E"; python3 "$G" delete --env "$E" --id <post_id>
```
**.env cần:** `FB_APP_ID FB_APP_SECRET FB_PAGE_ID FB_PAGE_ACCESS_TOKEN` (đặt ngoài repo hoặc `.gitignore` + chmod 600).
- **2 GOTCHA đã trả giá:**
  1. **Page ID Graph API ≠ ID URL.** Page kiểu mới có ID URL (vd `6159…`) khác **ID node Graph** (vd `1095…`). Query/đăng bằng ID URL → `code 100 subcode 33 "does not exist"`. ⇒ lấy ID đúng từ `me/accounts` (get-token tự ghi đúng).
  2. **Thiếu `pages_manage_posts` → `(#200)` khi đăng.** App tạo theo **use case Ads/Doanh nghiệp KHÔNG kèm** quyền này; user phải vào **App → Use cases → "Quản lý mọi thứ trên Trang"** (hoặc Customize → Add `pages_manage_posts`) rồi Generate lại User token. Kiểm bằng `debug`.
- Token Page từ `me/accounts` (qua User token đã đổi dài-hạn) có `expires_at:0` = gần như không hết hạn.

### Ads Manager (khi cần) — dò bằng `inspect`
Vào `adsmanager.facebook.com` (hoặc business.facebook.com → Quảng cáo). Tạo campaign = nhiều bước (mục tiêu →
ngân sách → đối tượng → quảng cáo). **Chạy ads = TỐN TIỀN → luôn duyệt trước.** Chưa có hàm sẵn → dùng vòng lặp `inspect`,
xong thì bổ sung hàm vào `meta_cdp.py`.

## Khi nào nâng cấp skill
Làm xong 1 thao tác Meta mới (vd tạo ad, mời thành viên BM, lên lịch bài) → **thêm hàm vào `meta_cdp.py` + 1 dòng recipe ở đây**
để lần sau gọi thẳng, khỏi dò.
