#!/usr/bin/env python3
"""Graph API helper cho engine (máy-gọi-máy, KHÔNG điều khiển trình duyệt FB).

Vì sao tách khỏi meta_cdp.py: thao tác Business/Ads/đăng-bài-định-kỳ KHÔNG được tự
động qua trình duyệt facebook.com (Meta gắn cờ "Tính toàn vẹn tài khoản" — đã dính
2026-06-27). Đăng bài hợp lệ = Graph API + Page Access Token (server-to-server).

Đọc key từ 1 file .env (NGOÀI repo hoặc đã .gitignore). KHÔNG in token ra màn hình.

CLI:
  python3 graph_api.py get-token --env PATH   # User token tạm -> Page token không hết hạn, ghi vào .env
  python3 graph_api.py debug    --env PATH     # in scopes + hạn token (không in token)
  python3 graph_api.py feed     --env PATH [--limit 10]
  python3 graph_api.py post     --env PATH --message "..."        # đăng -> in post_id
  python3 graph_api.py delete   --env PATH --id <post_id>

.env cần: FB_APP_ID, FB_APP_SECRET, FB_PAGE_ID, FB_PAGE_ACCESS_TOKEN
get-token cần thêm tạm: FB_USER_TOKEN_TEMP (script tự xoá sau khi dùng).
Quyền token để đăng bài: pages_manage_posts + pages_read_engagement (use case
"Quản lý mọi thứ trên Trang"; nếu thiếu pages_manage_posts -> thêm ở App > Use cases).
"""
import json, re, sys, socket, argparse, urllib.request, urllib.parse, urllib.error

VER = "v21.0"
socket.setdefaulttimeout(25)


def load_env(path):
    d, lines = {}, []
    with open(path, encoding="utf-8") as f:
        for line in f:
            lines.append(line.rstrip("\n"))
            s = line.strip()
            if not s or s.startswith("#") or "=" not in s:
                continue
            k, v = s.split("=", 1)
            d[k.strip()] = v.split("#", 1)[0].strip()
    return d, lines


def write_back(path, lines, updates):
    done, out = set(), []
    for line in lines:
        m = re.match(r"^(\s*)([A-Z0-9_]+)\s*=", line)
        if m and m.group(2) in updates:
            out.append(f"{m.group(2)}={updates[m.group(2)]}"); done.add(m.group(2))
        else:
            out.append(line)
    for k, v in updates.items():
        if k not in done:
            out.append(f"{k}={v}")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")


def _get(url):
    with urllib.request.urlopen(url, timeout=25) as r:
        return json.loads(r.read().decode())


def _req(url, data=None, method=None):
    body = urllib.parse.urlencode(data).encode() if data else None
    req = urllib.request.Request(url, data=body, method=method)
    with urllib.request.urlopen(req, timeout=25) as r:
        return json.loads(r.read().decode())


def _err(e):
    try:
        return e.read().decode()
    except Exception:
        return str(e)


def get_token(env_path):
    env, lines = load_env(env_path)
    need = [k for k in ("FB_APP_ID", "FB_APP_SECRET", "FB_USER_TOKEN_TEMP") if not env.get(k)]
    if need:
        print("⏸️  Thiếu trong .env:", ", ".join(need),
              "\n   FB_USER_TOKEN_TEMP = User token bấm Generate ở Graph API Explorer."); return 2
    q = urllib.parse.urlencode({"grant_type": "fb_exchange_token", "client_id": env["FB_APP_ID"],
                                "client_secret": env["FB_APP_SECRET"], "fb_exchange_token": env["FB_USER_TOKEN_TEMP"]})
    try:
        long_user = _get(f"https://graph.facebook.com/{VER}/oauth/access_token?{q}")["access_token"]
    except urllib.error.HTTPError as e:
        print("❌ Đổi token dài hạn lỗi (App ID/Secret sai hoặc User token hết hạn):\n" + _err(e)); return 1
    q = urllib.parse.urlencode({"fields": "id,name,access_token,tasks", "access_token": long_user})
    try:
        pages = _get(f"https://graph.facebook.com/{VER}/me/accounts?{q}").get("data", [])
    except urllib.error.HTTPError as e:
        print("❌ me/accounts lỗi:\n" + _err(e)); return 1
    if not pages:
        print("⚠️ me/accounts rỗng — thiếu pages_show_list hoặc chưa quản trị Page nào."); return 1
    want = env.get("FB_PAGE_ID")
    pg = next((p for p in pages if p["id"] == want), None) or (pages[0] if len(pages) == 1 else None) \
        or next((p for p in pages if "rent" in p.get("name", "").lower()), None)
    if not pg:
        print("Các Page:", [(p["id"], p["name"]) for p in pages], "\n⚠️ sửa FB_PAGE_ID rồi chạy lại."); return 1
    write_back(env_path, lines, {"FB_PAGE_ID": pg["id"], "FB_PAGE_ACCESS_TOKEN": pg["access_token"],
                                 "FB_USER_TOKEN_TEMP": ""})
    print(f"✅ Ghi Page token cho '{pg['name']}' (id {pg['id']}) vào .env. Đã xoá FB_USER_TOKEN_TEMP."); return 0


def debug(env_path):
    env, _ = load_env(env_path)
    t = urllib.parse.quote(env["FB_PAGE_ACCESS_TOKEN"])
    d = _get(f"https://graph.facebook.com/{VER}/debug_token?input_token={t}&access_token={t}")["data"]
    print("type:", d.get("type"), "| expires_at:", d.get("expires_at"), "(0 = không hết hạn)")
    print("scopes:", d.get("scopes"))
    print("đăng bài được?", "✅" if "pages_manage_posts" in d.get("scopes", []) else "❌ thiếu pages_manage_posts")


def feed(env_path, limit=10):
    env, _ = load_env(env_path)
    t = urllib.parse.quote(env["FB_PAGE_ACCESS_TOKEN"])
    data = _get(f"https://graph.facebook.com/{VER}/{env['FB_PAGE_ID']}/feed?fields=id,message,created_time&limit={limit}&access_token={t}").get("data", [])
    print(f"{len(data)} bài:")
    for p in data:
        print("  -", p["id"], "|", (p.get("message") or "(rỗng=story ảnh)")[:60])


def post(env_path, message):
    env, _ = load_env(env_path)
    tok = env["FB_PAGE_ACCESS_TOKEN"]
    r = _req(f"https://graph.facebook.com/{VER}/{env['FB_PAGE_ID']}/feed",
             {"message": message, "access_token": tok})
    print("✅ post_id =", r["id"]); return r["id"]


def delete(env_path, post_id):
    env, _ = load_env(env_path)
    t = urllib.parse.quote(env["FB_PAGE_ACCESS_TOKEN"])
    print(_req(f"https://graph.facebook.com/{VER}/{post_id}?access_token={t}", method="DELETE"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["get-token", "debug", "feed", "post", "delete"])
    ap.add_argument("--env", default=".env")
    ap.add_argument("--message"); ap.add_argument("--id"); ap.add_argument("--limit", type=int, default=10)
    a = ap.parse_args()
    try:
        if a.cmd == "get-token": return get_token(a.env)
        if a.cmd == "debug": return debug(a.env)
        if a.cmd == "feed": return feed(a.env, a.limit)
        if a.cmd == "post": return post(a.env, a.message)
        if a.cmd == "delete": return delete(a.env, a.id)
    except urllib.error.HTTPError as e:
        print("❌ HTTP lỗi:\n" + _err(e)); return 1


if __name__ == "__main__":
    sys.exit(main() or 0)
