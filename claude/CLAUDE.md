# Global rules for Claude Code

Synced from `github.com/Gin111191/zsh` → `claude/CLAUDE.md`, symlinked to
`~/.claude/CLAUDE.md`. Applies to every project, on every machine.

## Shell
- The Bash tool runs NON-INTERACTIVE: aliases from `~/.config/zsh/aliases.zsh`
  (`ls`→eza, `cat`→bat, `grep`→rg) are NOT loaded. Call binaries directly.
- ZDOTDIR is `~/.config/zsh` (a git repo). There is no `~/.zshrc` in `$HOME`.
- Never let a pager block: `git --no-pager …`, and `bat -pp` rather than bare `bat`.
- Machine-local shell overrides belong in `~/.config/zsh/local.zsh` (gitignored).
- `~/.config/zsh/plugins/zsh-vi-mode/zsh-vi-mode.zsh` holds a NUL byte, on EVERY machine
  (it ships in the repo), so both searchers go into binary mode on it:
  plain `grep` prints nothing and exits 1 — it reads as "pattern absent", which is a lie;
  plain `rg` does match and `rg -c` counts correctly, but in place of the lines it prints
  `binary file matches (found "\0" byte ...)`.
  Use `rg -a` (or `grep -a`) whenever you need the actual lines out of that file.

## CLI tools — prefer these
This is the stack README → Install puts on every machine. Present in practice, but
`command -v` before leaning on any one of them — see *Any machine* below.
- `rg` content search, `fd` file search. Both honour .gitignore; `-u` overrides that,
  `-uu` also includes hidden files.
- `ast-grep` — structural search over the AST, for multi-line or syntax-shaped
  patterns `rg` cannot express. Invoke as `ast-grep`; the `sg` alias is deprecated
  upstream and is deliberately not installed.
- `jq` JSON. `yq` YAML/TOML/XML — **mikefarah v4 syntax**; apt's `yq` is the
  unrelated python v3, so install v4 from the release binary (README → Install).
- `gh` GitHub CLI (authenticated), `bat`, `eza`, `btop`, `nvim`, `tmux`.
- `fzf`, `zoxide`: interactive-only, useless in a non-interactive Bash call.

## Absent on every machine checked so far
delta, sd, hyperfine, dust, duf, procs, tldr, watchexec, direnv, mise, cargo.
Treat as absent, but this is an observation, not a guarantee — `command -v` settles it.
`btop` is the other way round: it is in the list above yet missing on some machines.

## Any machine — probe, never assume
This file is cloned onto every machine, so nothing above is guaranteed by the OS name
alone. Each check below is one cheap command; run it instead of guessing.

| Question | Command | Why it matters |
|---|---|---|
| Is the tool here? | `command -v <tool>` | The tool list is what the README installs, not what this box has. |
| Can I install it? | `sudo -n true` | Exit 0 = passwordless. Otherwise hand the user the command, do not run it. |
| Which package manager? | `brew --prefix`, else `apt` / `paru` | See README → Install for the per-OS line. |
| Does the terminal do OSC 52? | `$TERM_PROGRAM`, `$TERM` | WezTerm, iTerm2, kitty, Windows Terminal do; conhost does not, and fails silently. |
| Am I inside tmux? | `[[ -n $TMUX ]]` | Decides which store `p` reads. README → Shared clipboard. |
| How heavy is `$HOME`? | `du -h -d1 ~` | Cloud-sync folders and toolchain caches make a bare `~` search take minutes. Always scope to a project directory. |

Anything verified on one specific box goes in a `## Machine: …` section below, so the
generic rules stay true everywhere.

## Machine: WSL2, Ubuntu 26.04, hostname GIN-PC
- Windows drives mount at `/mnt/c`, `/mnt/d` and `/mnt/f`. I/O there is ~10x slower than the
  Linux side — never search `/mnt/*` unless asked explicitly.
- `$HOME` holds ~266k files (`anaconda3`, `Everything_in_Gin` ≈ 16 GB together).
  Scope searches to a project directory, never bare `~`.
- `sudo` requires a password, so I cannot install packages. Hand the user the
  command instead of trying.
- The terminal is **conhost**, the legacy Windows console — not Windows Terminal. It
  ignores OSC 52 silently, so anything relying on the terminal to set the host clipboard
  fails without an error. `clip.exe` (37 ms) is the working path to the Windows clipboard;
  `powershell.exe -NoProfile -Command Get-Clipboard` (212 ms) reads it back.
- **I get here over SSH**, not through `wsl.exe`: `sshd -D` → `sshd-session` → `zsh` →
  `claude` (check with `ps -o args= -p $PPID` up the tree). The distro is started at boot
  by a scheduled task and is only ever reached by ssh, so no session in it inherits WSL's
  interop environment. `WSL_DISTRO_NAME`, `WSL_INTEROP`, `DISPLAY`, `WAYLAND_DISPLAY` are
  all unset, and `PATH` is whatever pam_env read out of `/etc/environment` — the Windows
  entries interop appends (19 of them, `wsl.exe -e sh -c 'echo $PATH'` shows them) never
  reach the shell. Consequences: `clip.exe` is NOT on PATH by default (`.zshenv` puts
  `/mnt/c/Windows/System32` back), and any "am I on WSL?" test written against
  `$WSL_DISTRO_NAME` is false on the one machine it was written for — probe the binary.
  Interop itself still works: `/init` falls back to `/run/WSL/1_interop`, so `.exe` files
  run fine, they just land in Windows **session 0**.
- WSLg cannot work here, and it is the autostart that decides that, not a bug in WSL.
  The instance is created at boot by a `schtasks` task (`wsl.exe -d Ubuntu -u root -e
  sleep infinity`, see github.com/Gin111191/wsl-autostart) and afterwards only ever
  reached by ssh, so no interactive Windows desktop session is ever bound to it: every
  interop socket in `/run/WSL/` dates from boot and lands in session 0, while the desktop
  is session 1 (`query.exe session`). `msrdc.exe`, the Windows half of WSLg, therefore
  starts with nothing to draw on, drops the RDP peer after **101.7 s**, and weston's
  `rdp-backend.so` NULL-derefs on the disconnect path (`segfault at 218`, see
  `/mnt/wslg/stderr.log` and `dmesg | grep weston`). WSLGd restarts it, forever: ~850
  SIGSEGVs and ~13 MB of `/mnt/wslg/weston.log` per day. Xwayland loses its compositor in
  the same cycle (`(EE) could not connect to wayland server`), which is why `xdpyinfo`
  hangs rather than fails. Updating WSL does not help (2.7.14.0 / WSLg 1.0.73.2 still
  loops); the only real choices are `guiApplications=false` in `%USERPROFILE%\.wslconfig`
  to stop the loop, or giving up pre-login ssh and creating the instance from a logged-in
  desktop. So: no Wayland, no X11, `wl-copy`/`wl-paste`/`xdpyinfo` and every Linux GUI app
  hang, `wl-clipboard` is inert. Do not propose anything that needs a display.
