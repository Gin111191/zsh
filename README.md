# zsh config

My personal zsh configuration — minimal, fast, and portable across Linux / macOS / WSL.
Based on [radleylewis/zsh](https://github.com/radleylewis/zsh), with my own customizations.

## What's inside

| File | Purpose |
|------|---------|
| `.zprofile` | Login-time setup: Homebrew shellenv (Apple Silicon / Intel / Linuxbrew), then re-sources `~/.zprofile` |
| `.zshenv` | Environment: XDG dirs, `EDITOR=nvim`, `MANPAGER` via bat, Starship config path, `~/.local/bin` in PATH |
| `.zshrc` | History, shell options, completion, fzf keybindings loader, sources the modular files, portable conda init |
| `aliases.zsh` | eza/bat/ripgrep aliases, git shortcuts, `lf` cd-on-exit wrapper, `v` → nvim |
| `bindings.zsh` | Vi-mode cursor shapes + custom keybindings (registered via `zvm_after_init`) |
| `clipboard.zsh` | Shared clipboard for vi-mode yank/paste — tmux paste-buffer as the single store |
| `fzf.zsh` | fzf defaults (fd-backed, bat preview), `Ctrl+F` no-hidden file picker |
| `plugins.zsh` | Tiny built-in plugin manager (git clone on first launch, `zplugin-update` to update) |
| `prompt.zsh` | Prompt housekeeping (`VIRTUAL_ENV_DISABLE_PROMPT`) |
| `starship.toml` | Starship prompt: directory, OS icon, git branch/status, conda env, node/rust/go/php |
| `claude/CLAUDE.md` | Global rules for Claude Code — symlinked to `~/.claude/CLAUDE.md` (see below) |

## Stack

- **Prompt:** [starship](https://starship.rs) (requires a [Nerd Font](https://www.nerdfonts.com))
- **Plugins:** zsh-autosuggestions, zsh-history-substring-search, zsh-vi-mode, fast-syntax-highlighting — auto-installed into `plugins/` on first launch, no plugin manager needed
- **Navigation:** zoxide, fzf, fd, lf
- **CLI tools:** eza, bat, ripgrep, ast-grep, jq, yq, gh, neovim
- **Extras:** conda auto-init (only if anaconda3/miniconda3 is installed), NVM-ready

## My changes vs upstream

- `alias v='nvim'` instead of `alias vim='nvim'`
- Starship is initialized inside `zvm_after_init` (together with fast-syntax-highlighting) so the prompt and highlighting survive zsh-vi-mode's keybinding reset
- Starship prompt shows the active **conda** environment (base env hidden)
- Portable conda initialization block (works on any machine, skipped if conda isn't installed)

## Install

### 1. Dependencies

**Ubuntu / Debian / WSL**

```sh
sudo apt install zsh neovim eza bat fd-find fzf ripgrep jq gh unzip wl-clipboard
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
curl -sS https://starship.rs/install.sh | sh
# Ubuntu names bat/fd differently — symlink them:
mkdir -p ~/.local/bin
ln -sf $(which batcat) ~/.local/bin/bat
ln -sf $(which fdfind) ~/.local/bin/fd
# yq v4 and ast-grep are not packaged — apt's `yq` is the unrelated python v3:
curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o ~/.local/bin/yq && chmod +x ~/.local/bin/yq
curl -sL https://github.com/ast-grep/ast-grep/releases/latest/download/app-x86_64-unknown-linux-gnu.zip \
  -o /tmp/ast-grep.zip && unzip -j -o /tmp/ast-grep.zip ast-grep -d ~/.local/bin
```

> `wl-clipboard` is what makes yank/paste reach the system clipboard **outside** tmux.
> Inside tmux it is not needed — `clipboard.zsh` uses the tmux buffer instead.
> On WSL it needs a working WSLg compositor; see *Troubleshooting* if yank stops
> reaching the system clipboard outside tmux.

**macOS**

```sh
brew install zsh neovim eza bat fd fzf zoxide starship ripgrep ast-grep jq yq gh
```

**Arch**

```sh
paru -S zsh neovim eza bat fd fzf zoxide starship ripgrep ast-grep jq yq wl-clipboard
```

> **Windows:** use WSL and follow the Ubuntu instructions.

### 2. Clone

```sh
git clone https://github.com/Gin111191/zsh ~/.config/zsh
```

### 3. Point zsh at the config

Either add to `/etc/zsh/zshenv` (system-wide, what I use):

```sh
if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi
if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
  export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
```

…or, without root, create `~/.zshenv` with:

```sh
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
```

Either way, `~/.zprofile` and `~/.zshrc` in `$HOME` stop being read — zsh reads them from
`$ZDOTDIR` instead. This repo's `.zprofile` sets up Homebrew (Apple Silicon, Intel or Linuxbrew,
whichever it finds) and then sources `~/.zprofile` at the end, so anything an installer writes
there (nvm, conda, rustup…) still runs instead of failing silently.

### 4. Finish

```sh
chsh -s $(which zsh)          # make zsh the default shell
mkdir -p ~/.local/state/zsh   # history file location
mkdir -p ~/.cache/zsh         # completion cache
```

Open a new terminal — plugins install themselves on first launch.

Machine-specific tweaks go in `~/.config/zsh/local.zsh` (gitignored, sourced automatically if present).

### 5. Claude Code rules (optional)

`claude/CLAUDE.md` holds the global rules Claude Code loads in every project — which CLI
tools exist here, that the Bash tool never sees the aliases in `aliases.zsh`, and the
per-machine gotchas. Symlink it so both machines stay in step:

```sh
mkdir -p ~/.claude
ln -sf ~/.config/zsh/claude/CLAUDE.md ~/.claude/CLAUDE.md
```

It is one file with a section per machine, labelled by OS. Add a machine before trusting
its section — the macOS one is still a stub.

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file search incl. hidden files (fzf + fd) |
| `Ctrl+F` | Fuzzy file search excl. hidden files |
| `Ctrl+→` / `Ctrl+←` | Move forward / backward one word |
| `↑` / `↓` | History substring search |
| `Ctrl+\` | Toggle autosuggestions |
| `Esc` | Vi normal mode (zsh-vi-mode) |
| `y` then `p` | Yank / paste through the **shared** clipboard — see below |

## Shared clipboard

zsh-vi-mode yanks into ZLE's `$CUTBUFFER`, a variable that lives **inside the zsh
process**. Every tmux pane runs its own zsh, so each pane gets its own store and
`p` pastes something different in each one.

`clipboard.zsh` fixes that by making **tmux's paste-buffer the single store**:

```zsh
ZVM_CLIPBOARD_COPY_CMD='tmux load-buffer -w -'   # -w also pushes it out over OSC 52
ZVM_CLIPBOARD_PASTE_CMD='tmux save-buffer -'
```

One yank then reaches everywhere:

| Yanked in | Pasted in | |
|---|---|---|
| zsh vi-mode, pane A | zsh vi-mode, pane B (`p`) | ✓ |
| zsh vi-mode | any pane, `prefix + ]` | ✓ |
| zsh vi-mode | a GUI app on the local machine (`Cmd+V`) | ✓ via OSC 52 |
| tmux copy-mode (`y`) | zsh vi-mode (`p`) | ✓ |

The tmux branch is **OS-independent** — macOS, Linux over SSH and WSL all use the
same two lines. No `clip.exe`, no `xclip`, no OS detection.

`bindings.zsh` rebinds `p`/`P` to that shared store (the plugin normally reserves
it for `gp`/`gP`, mirroring vim's `"+p`), with a fallback to `$CUTBUFFER` so an
empty clipboard never makes `p` look like a dead key.

**Cost:** 3.8 ms per paste — `tmux save-buffer` talks to the local tmux server over
a unix socket, so SSH adds no network round-trip. It is twice as fast as `pbpaste`
(7.9 ms). Shell startup pays one ~4 ms probe for the `-w` flag (tmux ≥ 3.2).

**Limits:** `yy` loses its trailing newline (`$( )` strips it). OSC 52 is
write-only, so copying in a browser and pressing `p` in the shell will not work —
use `Cmd+V` for that direction. Needs `set -g set-clipboard on` in tmux, which
[tmux-config](https://github.com/Gin111191/tmux-config) already sets.

## Troubleshooting

**Outside tmux on WSL, yank never reaches the Windows clipboard.**

`zvm_clipboard_detect` only looks for `pbcopy`, `wl-copy`, `xclip` and `xsel`, and it needs
*both* a copy and a paste command before it treats the clipboard as usable. `clip.exe` exists
on WSL but the plugin never looks for it. So `wl-clipboard` is the fix — *provided WSLg's
compositor is alive*.

Check that first:

```sh
wl-copy </dev/null && echo ok        # "does not seem to implement seat" => weston is down
rg -c 'signal 11' /mnt/wslg/stderr.log   # count of compositor crashes since boot
```

On GIN-PC (2026-09-08) weston was crash-looping with SIGSEGV every ~102 s — 259 times since
boot — so wl-clipboard, XWayland and every Linux GUI app were all dead. `weston.log` showed the
rdprail app-list scan retrying two icons that do not exist on disk, then dying:

```
retry_find_icon_file: icon (/usr/local/cuda-13.1/libnvvp/icon.xpm) retry count (4)
free_app_entry(): (null): /usr/share/applications/openjdk-25-java.desktop
```

`nvvp.desktop` and `nsight.desktop` (CUDA 13.1) point at `icon.xpm` files that were never
installed. Suggestive, not proven. Try `wsl --shutdown` from Windows first; if the loop comes
back, move those two `.desktop` files aside and watch the crash count.

Not worth routing around it with `clip.exe` + `powershell Get-Clipboard`: measured at 212 ms per
paste against tmux's 5 ms, which is a visible stutter on every `p`. Inside tmux the shared
clipboard works regardless — that path does not touch WSLg at all.

## Updating plugins

```sh
zplugin-update
```

## Credits

Forked from [radleylewis/zsh](https://github.com/radleylewis/zsh) (MIT). See [LICENSE](./LICENSE).
