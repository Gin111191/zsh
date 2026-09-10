#!/usr/bin/env python3
"""
zalo-send — gửi 1+ file local vào 1 hội thoại Zalo Web (mặc định "My Documents")
qua Chrome đang chạy debug (cổng 9222), để xem/tải trên điện thoại.

Cách dùng:
    python3 send.py <file1> [file2 ...] [--to "My Documents"] [--port 9222]
                    [--render-html] [--no-render-html] [--dry-run]

Mặc định: file .html sẽ được render sang PDF trước khi gửi (HTML xem trên đt rất xấu).
Tắt bằng --no-render-html. Ép render bằng --render-html (cho mọi file — chỉ áp dụng html).

Tiền đề: Chrome chạy với --remote-debugging-port=9222 trên profile KHÔNG mặc định,
ĐÃ đăng nhập Zalo Web. Nếu 9222 không sống → script báo và dừng (không tự bật Chrome
để tránh đụng phiên Chrome bạn đang dùng).

An toàn: LUÔN xác minh header hội thoại == --to trước khi gửi; lệch → ABORT (không gửi nhầm).
"""
import argparse, glob, json, os, subprocess, sys, tempfile, time, urllib.request

def log(*a): print(*a, flush=True)
def norm(s): return " ".join((s or "").split())   # gộp khoảng trắng (kể cả nbsp  )

def cdp_alive(port):
    try:
        with urllib.request.urlopen(f"http://localhost:{port}/json/version", timeout=3) as r:
            return json.load(r).get("Browser")
    except Exception:
        return None

def find_headless_shell():
    pats = [
        os.path.expanduser("~/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell"),
        os.path.expanduser("~/Library/Caches/ms-playwright/chromium-*/chrome-mac*/Chromium.app/Contents/MacOS/Chromium"),
    ]
    hits = []
    for p in pats: hits += glob.glob(p)
    if not hits: return None
    # chọn bản version cao nhất theo tên thư mục
    return sorted(hits)[-1]

def render_html_to_pdf(html_path):
    shell = find_headless_shell()
    if not shell:
        raise RuntimeError("Không tìm thấy chrome-headless-shell (ms-playwright). Chạy: python3 -m playwright install chromium")
    out = os.path.join(tempfile.mkdtemp(prefix="zalo-send-"),
                       os.path.splitext(os.path.basename(html_path))[0] + ".pdf")
    prof = tempfile.mkdtemp(prefix="zs-chrome-")
    src = "file://" + os.path.abspath(html_path)
    cmd = [shell, "--no-sandbox", "--no-pdf-header-footer", "--virtual-time-budget=8000",
           "--run-all-compositor-stages-before-draw", f"--user-data-dir={prof}",
           f"--print-to-pdf={out}", src]
    subprocess.run(cmd, capture_output=True, timeout=60)
    if not os.path.exists(out) or os.path.getsize(out) == 0:
        raise RuntimeError(f"Render PDF thất bại: {html_path}")
    log(f"  render → {out} ({os.path.getsize(out)} bytes)")
    return out

def open_conversation(pg, target):
    # click item trong danh sách hội thoại có dòng tiêu đề == target
    pg.evaluate("""(target)=>{
        const items=document.querySelectorAll("[class*='conv-item'],[class*='conversation-item']");
        for(const e of items){
            const f=(e.innerText||'').split('\\n')[0].replace(/\\u00a0/g,' ').trim();
            if(f===target){ let t=e; for(let i=0;i<4&&t;i++){ if(t.offsetParent!==null){ t.scrollIntoView(); t.click(); return true; } t=t.parentElement; } }
        }
        return false;
    }""", target)
    pg.wait_for_timeout(1600)

def current_header(pg):
    return norm(pg.evaluate("""()=>{const e=document.querySelector("header [class*='title']");return e?e.innerText.split('\\n')[0]:''}"""))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--to", default="My Documents")
    ap.add_argument("--port", type=int, default=9222)
    ap.add_argument("--render-html", dest="render", action="store_true", default=None)
    ap.add_argument("--no-render-html", dest="render", action="store_false")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    # 1) kiểm file tồn tại
    for f in a.files:
        if not os.path.exists(f): log(f"❌ Không thấy file: {f}"); sys.exit(2)

    # 2) kiểm Chrome debug
    br = cdp_alive(a.port)
    if not br:
        log(f"❌ Chrome debug KHÔNG sống ở cổng {a.port}.")
        log("   Bật Chrome debug (profile riêng, đã đăng nhập Zalo) rồi chạy lại, ví dụ:")
        log('   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \\')
        log(f'     --remote-debugging-port={a.port} --user-data-dir="$HOME/.cache/claude-chrome-min" &')
        log("   Lần đầu: mở chat.zalo.me và quét QR đăng nhập (session lưu lại cho lần sau).")
        sys.exit(3)
    log(f"✓ Chrome debug: {br}")

    # 3) render html→pdf nếu cần
    to_send = []
    for f in a.files:
        is_html = f.lower().endswith((".html", ".htm"))
        do_render = a.render if a.render is not None else is_html
        if do_render and is_html:
            log(f"• render HTML → PDF: {os.path.basename(f)}")
            to_send.append(render_html_to_pdf(f))
        else:
            to_send.append(os.path.abspath(f))
    log("• sẽ gửi:", ", ".join(os.path.basename(x) for x in to_send))

    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.connect_over_cdp(f"http://localhost:{a.port}")
        ctx = b.contexts[0]
        zalo = [x for x in ctx.pages if "chat.zalo.me" in x.url]
        if zalo:
            pg = zalo[0]
        else:
            log("• Không có tab Zalo → mở mới chat.zalo.me")
            pg = ctx.new_page(); pg.goto("https://chat.zalo.me/"); pg.wait_for_timeout(4000)
        pg.bring_to_front()

        # đăng nhập?
        if not pg.query_selector("header [class*='title']") and "login" in pg.url.lower():
            log("❌ Zalo chưa đăng nhập trong Chrome này. Mở chat.zalo.me quét QR rồi chạy lại."); sys.exit(4)

        # mở đúng hội thoại + xác minh
        open_conversation(pg, a.to)
        hdr = current_header(pg)
        if hdr != norm(a.to):
            log(f"❌ Không mở được đúng hội thoại. Header hiện tại = {hdr!r}, cần {a.to!r}. ABORT (không gửi nhầm).")
            sys.exit(5)
        log(f"✓ Đang ở hội thoại: {hdr!r}")

        if a.dry_run:
            visible = pg.locator("[title='Đính kèm File']").first.is_visible()
            log(f"[dry-run] nút 'Đính kèm File' hiển thị: {visible} — KHÔNG gửi."); return

        # đính kèm: nút 'Đính kèm File' → popup 'Chọn File' (bung hộp chọn file)
        pg.locator("[title='Đính kèm File']").first.click()
        pg.wait_for_timeout(900)
        with pg.expect_file_chooser(timeout=12000) as fc:
            pg.get_by_text("Chọn File", exact=True).first.click()
        fc.value.set_files(to_send)
        log("• đã nạp file vào ô soạn")
        pg.wait_for_timeout(2500)

        # gửi: nút 'Gửi'/'Send' nếu có, không thì Enter
        btn = pg.evaluate("""()=>{const c=[...document.querySelectorAll("button,[role='button'],div")].filter(e=>{const t=(e.innerText||'').trim();const r=e.getBoundingClientRect();return r.width>0&&r.height>0&&e.offsetParent!==null&&(t==='Gửi'||t==='Send')});if(c.length){c[c.length-1].click();return true}return false}""")
        if not btn: pg.keyboard.press("Enter")
        pg.wait_for_timeout(5000)

        # xác minh: tên file cuối xuất hiện gần đây trong hội thoại 'My Documents'
        want = os.path.basename(to_send[-1])
        ok = pg.evaluate("""(name)=>{
            const els=[...document.querySelectorAll("[class*='preview-message'],[class*='file-message']")];
            return els.some(e=>(e.innerText||'').includes(name));
        }""", want)
        if ok:
            log(f"✅ Đã gửi: {', '.join(os.path.basename(x) for x in to_send)} → {a.to!r}")
        else:
            log(f"⚠️ Đã thao tác gửi nhưng chưa xác minh thấy '{want}' trong hội thoại — kiểm lại Zalo."); sys.exit(6)

if __name__ == "__main__":
    main()
