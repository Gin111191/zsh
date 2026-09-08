# Global rules for Claude Code

Synced from `github.com/Gin111191/zsh` → `claude/CLAUDE.md`, symlinked to
`~/.claude/CLAUDE.md`. Applies to every project, on every machine.

## Shell
- The Bash tool runs NON-INTERACTIVE: aliases from `~/.config/zsh/aliases.zsh`
  (`ls`→eza, `cat`→bat, `grep`→rg) are NOT loaded. Call binaries directly.
- ZDOTDIR is `~/.config/zsh` (a git repo). There is no `~/.zshrc` in `$HOME`.
- Never let a pager block: `git --no-pager …`, and `bat -pp` rather than bare `bat`.
- Machine-local shell overrides belong in `~/.config/zsh/local.zsh` (gitignored).

## CLI tools — prefer these
Installed on WSL; the macOS box installs the same stack via brew (README → Install).
- `rg` content search, `fd` file search. Both honour .gitignore; `-u` overrides that,
  `-uu` also includes hidden files.
- `ast-grep` — structural search over the AST, for multi-line or syntax-shaped
  patterns `rg` cannot express. Invoke as `ast-grep`; the `sg` alias is deprecated
  upstream and is deliberately not installed.
- `jq` JSON. `yq` YAML/TOML/XML — **mikefarah v4 syntax**; apt's `yq` is the
  unrelated python v3, so install v4 from the release binary (README → Install).
- `gh` GitHub CLI (authenticated), `bat`, `eza`, `btop`, `nvim`, `tmux`.
- `fzf`, `zoxide`: interactive-only, useless in a non-interactive Bash call.

## Not installed — do not reach for these
delta, sd, hyperfine, dust, duf, procs, tldr, watchexec, direnv, mise, cargo.

## Machine: WSL2, Ubuntu 26.04, hostname GIN-PC
- Windows drives mount at `/mnt/c` and `/mnt/f`. I/O there is ~10x slower than the
  Linux side — never search `/mnt/*` unless asked explicitly.
- `$HOME` holds ~266k files (`anaconda3`, `Everything_in_Gin` ≈ 16 GB together).
  Scope searches to a project directory, never bare `~`.
- `sudo` requires a password, so I cannot install packages. Hand the user the
  command instead of trying.
- `plugins/zsh-vi-mode/zsh-vi-mode.zsh` contains a NUL byte: `grep` treats it as
  binary and silently prints nothing. Use `rg` (or `grep -a`) on that file.
- `lf` is not installed here, though `aliases.zsh` defines an `lf()` wrapper.
- The terminal is **conhost**, the legacy Windows console — not Windows Terminal. It
  ignores OSC 52 silently, so anything relying on the terminal to set the host clipboard
  fails without an error. `clip.exe` (37 ms) is the working path to the Windows clipboard;
  `powershell.exe -NoProfile -Command Get-Clipboard` (212 ms) reads it back.
- WSLg is broken: weston crash-loops with SIGSEGV every ~102 s (259 times in one day's
  uptime, 2026-09-08). There is no working Wayland or X11 display — `wl-copy`, `wl-paste`,
  `xdpyinfo` and every Linux GUI app fail or hang; `wl-clipboard` is installed but inert.
  Do not propose anything that needs a display.

## Machine: macOS
- Not surveyed yet. Fill this in from that machine before relying on it.
