#!/usr/bin/env python3
"""
meta_cdp.py — Thư viện + CLI thao tác Meta (Facebook Page / Business Manager / Ads)
qua Chrome đang chạy debug (CDP cổng 9222), dùng playwright (đăng nhập sẵn của user).

Mục tiêu: gói các công thức ĐÃ-CHẠY-ĐƯỢC để lần sau NHANH (không dò selector lại).
Dùng cho mọi project (đặt ở ~/.claude/skills/meta-ops).

Tiền đề:
  - Chrome debug cổng 9222 đã đăng nhập Facebook (xem SKILL.md để bật).
  - playwright python (user-site).  python3 -m pip install --user playwright

CLI:
  python3 meta_cdp.py inspect [--url URL] [--out shot.png]      # chụp + liệt kê nút/menu/input (dò UI)
  python3 meta_cdp.py render <html> <out.png> <w> <h>           # render HTML -> PNG (ảnh avatar/cover/card)
  python3 meta_cdp.py page-id "<Tên Page>"                      # lấy Page ID từ danh sách Trang bạn quản lý
  python3 meta_cdp.py create-page --name N --category C [--bio B]   # tạo Fanpage + trả Page ID
  python3 meta_cdp.py set-avatar --page-id ID --img a.png       # đăng ảnh đại diện
  python3 meta_cdp.py set-cover  --page-id ID --img c.png       # đăng ảnh bìa

GHI CHÚ QUAN TRỌNG (gotcha đã học):
  * set_viewport_size KHÔNG bền giữa các lần chạy script qua CDP -> LUÔN set lại mỗi lần (hàm get_tab lo).
  * Ảnh chụp trả về theo kích thước CỬA SỔ thật của Chrome (có thể nhỏ hơn viewport set) -> đọc nội dung là chính.
  * Sửa avatar/bìa: PHẢI "Dùng Facebook với tư cách Trang" (nút "Chuyển ngay" -> "Dùng Trang"); chế độ
    "Quản lý trang" KHÔNG có nút camera.
  * Upload 2 kiểu: (a) input ẩn -> set_input_files; (b) hộp chọn file hệ thống -> expect_file_chooser.
    "Tải ảnh lên" của ẢNH BÌA = kiểu (b) -> BẮT BUỘC expect_file_chooser, nếu click chay sẽ rơi vào
    "Tạo bài viết" (đăng ảnh thành bài) -> sai. Lỡ vào thì nhấn Escape huỷ.
  * Tạo Page: 1 cú click "Tạo Trang" có thể ĐÃ tạo dù URL không đổi; click lại -> báo trùng tên =>
    coi như đã tạo, đi xác minh bằng page-id thay vì bấm lại.
"""
import os, re, sys, argparse
from playwright.sync_api import sync_playwright

CDP = "http://localhost:9222"
VP = {"width": 1280, "height": 900}
FB = "https://www.facebook.com"


# ---------- nền tảng ----------
def attach(p):
    b = p.chromium.connect_over_cdp(CDP)
    if not b.contexts:
        raise RuntimeError("Chrome 9222 không có context — Chrome đã mở chưa?")
    return b, b.contexts[0]


def get_tab(ctx, contains=None, goto=None, vp=VP, wait=1500):
    """Lấy tab có URL chứa `contains` (hoặc mở tab mới), set viewport, (tuỳ chọn) điều hướng."""
    pg = None
    if contains:
        for t in ctx.pages:
            try:
                if contains in t.url:
                    pg = t; break
            except Exception:
                pass
    if pg is None:
        pg = ctx.new_page()
    pg.bring_to_front()
    if goto:
        pg.goto(goto, wait_until="domcontentloaded", timeout=45000)
    try:
        pg.set_viewport_size(vp)
    except Exception:
        pass
    pg.wait_for_timeout(wait)
    return pg


def click_text(pg, text, exact=True, timeout_wait=0):
    """Click phần tử click-được đầu tiên có text khớp (button/role=button/menuitem/a/span)."""
    sels = 'div[role="button"], a[role="button"], button, [role="menuitem"], span'
    for el in pg.query_selector_all(sels):
        try:
            t = (el.inner_text() or "").strip()
        except Exception:
            continue
        if (t == text if exact else text in t) and el.is_visible():
            el.click()
            if timeout_wait:
                pg.wait_for_timeout(timeout_wait)
            return True
    return False


def click_dialog_btn(pg, text):
    """Click nút có text chính xác trong dialog đang mở (vd Lưu / Xác nhận / Tiếp)."""
    dlg = pg.get_by_role("dialog")
    try:
        for el in dlg.locator('div[role="button"], button').all():
            if el.inner_text().strip() == text and el.is_visible():
                el.click(); return True
    except Exception:
        pass
    return click_text(pg, text)


def fill_label(pg, label_regex, value):
    loc = pg.get_by_label(re.compile(label_regex))
    loc.first.click(); pg.wait_for_timeout(200)
    try:
        loc.first.fill(value)
    except Exception:
        pg.keyboard.type(value, delay=15)
    pg.wait_for_timeout(200)


def set_file_input(pg, path):
    """Nạp file vào input[type=file] cuối cùng (kiểu upload ẩn)."""
    fis = pg.query_selector_all('input[type="file"]')
    if not fis:
        return False
    fis[-1].set_input_files(os.path.abspath(path))
    return True


def upload_via_chooser(pg, trigger_text, path, exact=True):
    """Bấm `trigger_text` để bung hộp chọn file hệ thống rồi nạp file (expect_file_chooser)."""
    with pg.expect_file_chooser(timeout=10000) as fc:
        click_text(pg, trigger_text, exact=exact)
    fc.value.set_files(os.path.abspath(path))
    return True


def dump(pg):
    """In nhanh nút/menu/aria/file-input để dò UI lạ."""
    print("URL:", pg.url)
    print("file inputs:", len(pg.query_selector_all('input[type="file"]')))
    seen = set()
    print("-- buttons/menuitems (text) --")
    for el in pg.query_selector_all('div[role="button"], a[role="button"], button, [role="menuitem"]'):
        try:
            t = (el.inner_text() or "").strip()
        except Exception:
            continue
        if t and len(t) < 45 and t not in seen and el.is_visible():
            seen.add(t); print("  ", repr(t))
    print("-- aria-label đáng chú ý --")
    for el in pg.query_selector_all('[aria-label]'):
        al = el.get_attribute("aria-label") or ""
        if any(k in al.lower() for k in ["ảnh", "camera", "bìa", "đại diện", "chỉnh sửa", "tải"]):
            print("  ", repr(al[:50]))


def ensure_acting_as_page(pg):
    """Bảo đảm đang 'dùng Facebook với tư cách Trang' (để hiện nút sửa avatar/bìa)."""
    if click_text(pg, "Chuyển ngay"):
        pg.wait_for_timeout(4000)
    click_text(pg, "Dùng Trang"); pg.wait_for_timeout(2000)
    pg.keyboard.press("Escape"); pg.wait_for_timeout(800)


# ---------- recipe ----------
def render_html(pg, html, out, w, h):
    pg.set_viewport_size({"width": int(w), "height": int(h)})
    pg.goto("file://" + os.path.abspath(html), wait_until="domcontentloaded")
    pg.wait_for_timeout(1200)
    pg.screenshot(path=os.path.abspath(out), clip={"x": 0, "y": 0, "width": int(w), "height": int(h)})
    return out


def get_page_id(pg, name):
    pg.goto(f"{FB}/pages/?category=your_pages", wait_until="domcontentloaded", timeout=45000)
    pg.wait_for_timeout(5000)
    for a in pg.query_selector_all('a[href*="profile.php?id="]'):
        try:
            if name.lower() in (a.inner_text() or "").lower():
                m = re.search(r"id=(\d+)", a.get_attribute("href") or "")
                if m:
                    return m.group(1)
        except Exception:
            pass
    # fallback: bất kỳ link page có tên
    for a in pg.query_selector_all('a[href]'):
        try:
            if name.lower() in (a.inner_text() or "").lower() and "profile.php?id=" in (a.get_attribute("href") or ""):
                m = re.search(r"id=(\d+)", a.get_attribute("href"))
                if m:
                    return m.group(1)
        except Exception:
            pass
    return None


def create_page(pg, name, category, bio=""):
    pg.goto(f"{FB}/pages/create/?ref_type=site_footer", wait_until="domcontentloaded", timeout=45000)
    pg.wait_for_timeout(4000)
    fill_label(pg, "Tên Trang", name)
    if bio:
        fill_label(pg, "Tiểu sử", bio)
    cat = pg.get_by_label(re.compile("Hạng mục"))
    cat.first.click(); pg.wait_for_timeout(300)
    pg.keyboard.type(category[:20], delay=40); pg.wait_for_timeout(2500)
    try:
        pg.get_by_role("option", name=category, exact=True).first.click()
    except Exception:
        # chọn option đầu nếu không khớp tuyệt đối
        opt = pg.query_selector('[role="option"]')
        if opt:
            opt.click()
    pg.wait_for_timeout(1000)
    btn = pg.get_by_role("button", name=re.compile(r"^Tạo Trang$"))
    if btn.first.is_enabled():
        btn.first.click()
    pg.wait_for_timeout(6000)
    return get_page_id(pg, name)


def set_avatar(pg, page_id, img):
    pg.goto(f"{FB}/profile.php?id={page_id}", wait_until="domcontentloaded", timeout=45000)
    pg.wait_for_timeout(4000)
    ensure_acting_as_page(pg)
    # bấm mục "Thêm ảnh đại diện" (hoặc "Chỉnh sửa ảnh đại diện")
    clicked = False
    for el in pg.query_selector_all('div[role="button"], a[role="button"]'):
        t = (el.inner_text() or "").strip()
        if (t.startswith("Thêm ảnh đại diện") or "ảnh đại diện" in t.lower()) and el.is_visible():
            el.click(); clicked = True; break
    pg.wait_for_timeout(2500)
    if not set_file_input(pg, img):
        # thử kiểu hộp chọn file
        upload_via_chooser(pg, "Tải ảnh lên", img)
    pg.wait_for_timeout(4000)
    click_dialog_btn(pg, "Lưu")
    pg.wait_for_timeout(6000)
    return True


def set_cover(pg, page_id, img):
    pg.goto(f"{FB}/profile.php?id={page_id}", wait_until="domcontentloaded", timeout=45000)
    pg.wait_for_timeout(4000)
    ensure_acting_as_page(pg)
    if not click_text(pg, "Thêm ảnh bìa"):
        click_text(pg, "Chỉnh sửa ảnh bìa")
    pg.wait_for_timeout(1500)
    # "Tải ảnh lên" của ảnh bìa = hộp chọn file hệ thống
    upload_via_chooser(pg, "Tải ảnh lên", img)
    pg.wait_for_timeout(5000)
    click_text(pg, "Lưu thay đổi")
    pg.wait_for_timeout(7000)
    return True


# ---------- CLI ----------
def main():
    ap = argparse.ArgumentParser(description="Thao tác Meta qua Chrome CDP 9222")
    sub = ap.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("inspect"); s.add_argument("--url"); s.add_argument("--out", default="/tmp/meta_inspect.png")
    s = sub.add_parser("render"); s.add_argument("html"); s.add_argument("out"); s.add_argument("w"); s.add_argument("h")
    s = sub.add_parser("page-id"); s.add_argument("name")
    s = sub.add_parser("create-page"); s.add_argument("--name", required=True); s.add_argument("--category", required=True); s.add_argument("--bio", default="")
    s = sub.add_parser("set-avatar"); s.add_argument("--page-id", required=True); s.add_argument("--img", required=True)
    s = sub.add_parser("set-cover"); s.add_argument("--page-id", required=True); s.add_argument("--img", required=True)
    a = ap.parse_args()

    with sync_playwright() as p:
        b, ctx = attach(p)
        if a.cmd == "inspect":
            pg = get_tab(ctx, goto=a.url) if a.url else get_tab(ctx, contains="facebook.com")
            dump(pg); pg.screenshot(path=a.out); print("shot:", a.out)
        elif a.cmd == "render":
            pg = get_tab(ctx)
            print("rendered:", render_html(pg, a.html, a.out, a.w, a.h))
        elif a.cmd == "page-id":
            pg = get_tab(ctx, contains="facebook.com")
            print(get_page_id(pg, a.name) or "(không tìm thấy)")
        elif a.cmd == "create-page":
            pg = get_tab(ctx, contains="facebook.com")
            print("PAGE_ID:", create_page(pg, a.name, a.category, a.bio) or "(chưa lấy được — chạy page-id để kiểm)")
        elif a.cmd == "set-avatar":
            pg = get_tab(ctx, contains="facebook.com")
            set_avatar(pg, a.page_id, a.img); print("avatar OK")
        elif a.cmd == "set-cover":
            pg = get_tab(ctx, contains="facebook.com")
            set_cover(pg, a.page_id, a.img); print("cover OK")


if __name__ == "__main__":
    main()
