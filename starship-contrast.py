#!/usr/bin/env python3
"""WCAG AA check for starship.toml segment colors. Run after touching [palettes.*].

Only text segments are checked. The powerline separators in the top-level `format`
string are glyphs, not text, so contrast does not apply to them.
"""
import os, re, sys

CFG = os.environ.get("STARSHIP_CONFIG",
                     os.path.expanduser("~/.config/zsh/starship.toml"))
s = open(CFG).read()
pal = dict(re.findall(r"^(color_\w+) = '(#[0-9a-fA-F]{6})'", s, re.M))

def lum(h):
    c = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    c = [x / 12.92 if x <= .03928 else ((x + .055) / 1.055) ** 2.4 for x in c]
    return .2126 * c[0] + .7152 * c[1] + .0722 * c[2]

def cr(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + .05) / (lo + .05)

rows, bad = [], 0
for sec in re.finditer(r"^\[([\w.]+)\]$(.*?)(?=^\[|\Z)", s, re.M | re.S):
    name, body = sec.group(1), sec.group(2)
    if name.startswith("palettes"):
        continue
    for style in re.findall(r"['\"]([^'\"]*(?:fg:|bg:)[^'\"]*)['\"]", body):
        # fg:/bg: appear in either order, so pull each independently
        mf, mb = re.search(r"fg:([\w#]+)", style), re.search(r"bg:([\w#]+)", style)
        if not (mf and mb):
            continue
        fg, bg = mf.group(1), mb.group(1)
        f, b = pal.get(fg, fg), pal.get(bg, bg)
        if not (f.startswith("#") and b.startswith("#")):
            continue
        v = cr(f, b)
        bad += v < 4.5
        rows.append((v, name, fg, bg))

for v, n, fg, bg in sorted(rows):
    tag = "FAIL" if v < 4.5 else ("AA " if v < 7 else "AAA")
    print(f"{tag} {v:5.2f}  {n:<16} fg:{fg:<14} bg:{bg}")
print(f"\n{len(rows)} text segments — {'all pass' if not bad else f'{bad} FAIL'} (WCAG AA 4.5)")
sys.exit(1 if bad else 0)
