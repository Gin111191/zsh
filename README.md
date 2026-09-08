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

- **Prompt:** [starship](https://starship.rs) (needs a [Nerd Font](https://www.nerdfonts.com) — except on WezTerm, which bundles one; Install → *The font*)
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

Paste the commands in order. Nothing below assumes you already know zsh — if a step
says "check X first", that check is there because skipping it is the usual way this
install goes wrong.

### 1. Dependencies

**macOS**

Homebrew installs everything else, so it goes first. Skip this block if `brew --version`
already answers:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon; on Intel: /usr/local/bin/brew
```

That `eval` only fixes the terminal you are sitting in. Step 3 makes it permanent — this
repo's `.zprofile` finds brew on its own, at `/opt/homebrew`, `/usr/local` or Linuxbrew.

```sh
brew install neovim eza bat fd fzf zoxide starship ripgrep ast-grep jq yq gh tmux lf btop
brew install --cask font-hack-nerd-font
```

`zsh` is deliberately **not** in that list: macOS has shipped zsh as the default shell
since Catalina, so the system one already works and needs no `chsh`. Install brew's zsh
only if you want a newer version — then see step 4.

**Ubuntu / Debian / WSL**

```sh
sudo apt update
sudo apt install zsh neovim eza bat fd-find fzf ripgrep jq gh unzip tmux lf btop wl-clipboard
```

Five more are missing from apt, or are the wrong program under the right name:

```sh
mkdir -p ~/.local/bin
# Ubuntu ships bat and fd under other names:
ln -sf $(which batcat) ~/.local/bin/bat
ln -sf $(which fdfind) ~/.local/bin/fd
# zoxide and starship have official installers:
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
curl -sS https://starship.rs/install.sh | sh
# apt's `yq` is an unrelated python v3 with different syntax — take the v4 binary:
curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o ~/.local/bin/yq && chmod +x ~/.local/bin/yq
# ast-grep is not packaged at all:
curl -sL https://github.com/ast-grep/ast-grep/releases/latest/download/app-x86_64-unknown-linux-gnu.zip \
  -o /tmp/ast-grep.zip && unzip -j -o /tmp/ast-grep.zip ast-grep -d ~/.local/bin
```

Those five land in `~/.local/bin`, which has to be on `$PATH` or nothing finds them. From
step 3 onward this repo's `.zshenv` adds it; until then, run
`export PATH="$HOME/.local/bin:$PATH"` in the current terminal.

> `wl-clipboard` only matters **outside** tmux, where the plugin auto-detects
> `wl-copy`/`wl-paste` on its own. Inside tmux `clipboard.zsh` uses the tmux buffer and
> needs neither.

**Arch**

```sh
paru -S zsh neovim eza bat fd fzf zoxide starship ripgrep ast-grep jq yq gh tmux lf btop wl-clipboard
```

**The font**

Starship draws the prompt with icons from a [Nerd Font](https://www.nerdfonts.com). Without
one the prompt shows empty rectangles (tofu) and looks broken.

**One exception: WezTerm needs nothing.** It bundles `Symbols Nerd Font Mono` and falls back
to it automatically, so the icons render on a clean install. `wezterm ls-fonts` prints the
chain it actually resolved. Every other terminal — Terminal.app, iTerm2, Windows Terminal,
GNOME Terminal, Alacritty, kitty — needs the two steps below.

macOS already has the font from the `--cask` line above. On Linux:

```sh
mkdir -p ~/.local/share/fonts
curl -fLo /tmp/Hack.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
unzip -o /tmp/Hack.zip -d ~/.local/share/fonts/Hack
fc-cache -f
fc-list | grep -i "Hack Nerd Font" | head -3   # a line of output means it is registered
```

**Installing it is only half.** You then have to **select it in the terminal's own
settings** — Profile → Font → *Hack Nerd Font*. No command does this for you, and skipping
it is the usual reason the prompt still looks broken after installing the font.

> **WSL:** install the font in **Windows**, not in Linux — Windows draws the terminal, so
> that is where the font has to live. Then pick it in Windows Terminal's settings.

### 2. Clone

```sh
git clone https://github.com/Gin111191/zsh ~/.config/zsh
```

If `~/.config/zsh` already exists, move it aside first (`mv ~/.config/zsh ~/.config/zsh.old`)
— git refuses to clone into a non-empty directory.

### 3. Point zsh at the config

**Recommended, no root needed.** Create `~/.zshenv` with exactly this:

```sh
cat > ~/.zshenv <<'EOF'
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
```

<details>
<summary>System-wide alternative (needs root; the file path differs per OS)</summary>

Debian, Ubuntu and Arch already have `/etc/zsh/zshenv`. macOS does **not** ship an
`/etc/zshenv` — only `/etc/zshrc` — so there you create it. Add:

```sh
if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi
if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
  export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
```
</details>

Either way, `~/.zprofile` and `~/.zshrc` in `$HOME` stop being read — zsh reads them from
`$ZDOTDIR` instead. This repo's `.zprofile` sets up Homebrew (Apple Silicon, Intel or Linuxbrew,
whichever it finds) and then sources `~/.zprofile` at the end, so anything an installer writes
there (nvm, conda, rustup…) still runs instead of failing silently.

### 4. Finish

```sh
mkdir -p ~/.local/state/zsh   # history file lives here
mkdir -p ~/.cache/zsh         # completion cache
```

Then make zsh your login shell — **only if it is not already**. Check with `echo $SHELL`:

- **macOS:** already `/bin/zsh`. Nothing to do.
- **Ubuntu / Debian / WSL / Arch:** `chsh -s $(which zsh)`, then log out and back in.
- **If you installed zsh from Homebrew,** `chsh` refuses a shell that is not listed in
  `/etc/shells`:
  ```sh
  echo /opt/homebrew/bin/zsh | sudo tee -a /etc/shells
  chsh -s /opt/homebrew/bin/zsh
  ```

Open a new terminal. On first launch the four plugins clone themselves into `plugins/`,
which takes a few seconds and prints git output once — that is expected, not an error.

Machine-specific tweaks go in `~/.config/zsh/local.zsh` (gitignored, sourced automatically if present).

### 5. Check it worked

```sh
echo $ZDOTDIR                        # -> /home/you/.config/zsh
command -v starship eza rg fd tmux   # -> five paths, no blanks
```

- Prompt shows icons rather than boxes → the Nerd Font is selected.
- `Esc` then `p` pastes → vi-mode and the shared clipboard are live.
- Something errors on startup: `zsh -x -i -c exit 2>&1 | tail -40` prints the last lines
  zsh ran before it broke.
- To back out entirely: delete `~/.zshenv` (or your `/etc` edit) and zsh returns to
  `~/.zshrc` as if nothing happened. The repo in `~/.config/zsh` becomes inert.

### 6. Claude Code rules (optional)

`claude/CLAUDE.md` holds the global rules Claude Code loads in every project — which CLI
tools exist here, that the Bash tool never sees the aliases in `aliases.zsh`, and the
per-machine gotchas. Symlink it so every machine stays in step:

```sh
mkdir -p ~/.claude
ln -sf ~/.config/zsh/claude/CLAUDE.md ~/.claude/CLAUDE.md
```

It opens with rules that hold anywhere plus the one-command checks to probe a new box, then
a `## Machine: …` section per machine for what was actually verified there.

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

**Short answer: yank reaches everywhere; `p` is one-way in tmux.**

| | Outside tmux | Inside tmux |
|---|---|---|
| What `p` reads | the system clipboard (`pbpaste` / `wl-paste` / `xclip`) | the tmux paste-buffer |
| Yank in shell → `p` in another pane | n/a | ✓ |
| Yank in shell → paste into a GUI app | ✓ | ✓ (over OSC 52) |
| Copy in a browser → `p` in shell | ✓ | ✗ — use the terminal's own paste |

Only the last row surprises people. Inside tmux `p` deliberately reads the tmux buffer,
because that is the whole point — every pane pastes the same thing, even over SSH — so it
cannot also read whatever you just copied in a browser. For that direction use the
terminal's own right-click / `Ctrl+Shift+V`, which needs no config.

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
| zsh vi-mode | a GUI app on the local machine | ✓ — via OSC 52, or `clip.exe` on WSL |
| tmux copy-mode (`y`) | zsh vi-mode (`p`) | ✓ |

The tmux branch is **OS-independent** — macOS, Linux over SSH and WSL all use the
same two lines for the cross-pane store. No `xclip`, no OS detection.

Reaching the *host* clipboard is the part that is not universal. `-w` makes tmux emit
OSC 52, and the terminal emulator has to act on it. Windows Terminal, iTerm2, WezTerm and
kitty do; **conhost — the legacy Windows console — does not**, and it fails silently. So on
WSL `clipboard.zsh` writes to both stores instead:

```zsh
_zvm_wsl_copy() {                      # measured on GIN-PC:
  local buf=$(cat)
  print -rn -- "$buf" | tmux load-buffer -w -   # cross-pane `p`  →  5 ms
  print -rn -- "$buf" | clip.exe                # Ctrl+V in Windows → 37 ms
}
```

`clip.exe` handles UTF-8 (Vietnamese diacritics included) and multi-line text correctly.
Both writes live inside the `$TMUX` branch. Outside tmux both `ZVM_CLIPBOARD_*_CMD`
variables stay empty, which hands the job to the plugin's own `zvm_clipboard_detect` —
`pbcopy`/`pbpaste` on macOS, `wl-copy`/`xclip`/`xsel` on Linux. That is why `p` works in
*both* directions there: it is reading the real system clipboard, not a tmux buffer.

`bindings.zsh` rebinds `p`/`P` to that shared store (the plugin normally reserves
it for `gp`/`gP`, mirroring vim's `"+p`), with a fallback to `$CUTBUFFER` so an
empty clipboard never makes `p` look like a dead key.

Binding `vicmd` keys is trickier than it looks, and both traps fail **silently**:

- `zvm_bindkey` does not bind anything while `ZVM_LAZY_KEYBINDINGS` is on (the default).
  For any keymap other than `viins` it just appends to `ZVM_LAZY_KEYBINDINGS_LIST` and
  returns, and that list has already been consumed by the time `zvm_after_init` runs.
- A plain `bindkey -M vicmd` in `zvm_after_init` does apply — and then the **first `Esc`**
  wipes it, because that is when zsh-vi-mode replays the lazy list over the whole keymap.
  Check it right after opening a shell and the binding looks correct; press `Esc` once and
  it is back to `vi-put-after`.

So the `vicmd` bindings live in `_my_vicmd_bindings`, called from the plugin's
`zvm_after_lazy_keybindings` hook — which runs immediately after that replay — and also
from `_my_bindings` for the case where someone turns lazy keybindings off.

**Cost:** 3.8 ms per paste — `tmux save-buffer` talks to the local tmux server over
a unix socket, so SSH adds no network round-trip. It is twice as fast as `pbpaste`
(7.9 ms). Shell startup pays one ~4 ms probe for the `-w` flag (tmux ≥ 3.2).

**Limits:** `yy` loses its trailing newline (`$( )` strips it). Inside tmux the host →
shell direction does not go through `p`, because `p` reads the tmux buffer rather than the
host clipboard. Paste that direction with the terminal's own right-click / `Ctrl+Shift+V`, which
needs no config. Needs `set -g set-clipboard on` in tmux, which
[tmux-config](https://github.com/Gin111191/tmux-config) already sets.

## Troubleshooting

**Yank in zsh never reaches the Windows clipboard.**

`-w` only asks tmux to emit OSC 52; the terminal has to implement it. Check whether yours
does by writing the escape straight to the tty, bypassing tmux:

```sh
printf '\033]52;c;%s\a' "$(printf test-osc52 | base64 -w0)" > $(tmux display -p '#{client_tty}')
powershell.exe -NoProfile -Command Get-Clipboard    # still the old value => not supported
```

On GIN-PC it is not supported: the terminal is **conhost**, the legacy Windows console (no
`WindowsTerminal.exe` in the process list), and conhost ignores OSC 52 without error. Every
piece on the tmux side was already correct — `set-clipboard on`, `terminal-features[0]
xterm*:clipboard`, and capability `Ms` present in `tmux info` — so nothing there was worth
changing. `clipboard.zsh` routes around it with `clip.exe`, see *Shared clipboard*.

Switching to Windows Terminal would make the OSC 52 path work and the `clip.exe` branch
redundant — it is kept because it costs 37 ms and works on any Windows console.

## Updating plugins

```sh
zplugin-update
```

## Credits

Forked from [radleylewis/zsh](https://github.com/radleylewis/zsh) (MIT). See [LICENSE](./LICENSE).
