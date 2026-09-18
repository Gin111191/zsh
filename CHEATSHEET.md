# Cheatsheet — the shell

Everything this zsh config gives you, in one place: keys, aliases, and the search commands.

The command line has **two modes**, because zsh-vi-mode is installed:

- **Insert mode** — where you type. The cursor is a thin **beam**. Every new prompt starts here.
- **Normal mode** — Vim keys. The cursor is a **block**. Press `Esc` to get here, `i` to go back.

Several keys mean different things in the two modes; the tables say which one they need.

Neovim keys: `~/.config/nvim/CHEATSHEET.md` · tmux keys: `~/.local/share/tmux-config/CHEATSHEET.md`

---

## Quick answers — "how do I…"

| I want to… | In the shell | In Neovim |
|---|---|---|
| Find a file by name | `Ctrl+T`, type part of the name · or `fd name` | `Space + s + f` |
| List the files that contain a word | `rg -l "word"` | `Space + s + g`, type the word |
| See every line that contains a word | `rg "word"` | `Space + s + g` |
| Search for the word under the cursor | — | `Space + s + w` |
| Include files `.gitignore` hides (`.env`, `node_modules` …) | `fd -u name` · `rg -uu "word"` | `:Telescope find_files no_ignore=true` |
| Jump to a folder I use often | `z part-of-its-name` · `zi` to pick from a list | — |
| Go into a folder below this one | `Alt+C`, pick it | `Space + e` (file tree) |
| Find a command I ran before | type its start, then `↑` · or `Esc` then `Ctrl+R` | — |
| Edit a long command comfortably | `Esc` then `vv` — it opens in Neovim | — |
| Copy text from one tmux pane to another | `Esc`, `yy` (or `y` + motion) · in the other pane `Esc`, `p` | `y` / `p` |
| Make a config change take effect | `exec zsh` **in every shell already open** | quit and reopen |
| Clear the screen inside tmux | `Prefix + Ctrl+L` (plain `Ctrl+L` switches pane) · or `clear` | — |

---

## Typing and editing the command line

### Insert mode

| Key | What it does |
|---|---|
| `Ctrl+A` / `Ctrl+E` | Start / end of the line |
| `Ctrl+←` / `Ctrl+→` | Back / forward one word |
| `Ctrl+W` | Delete the word before the cursor |
| `Ctrl+K` | Delete from the cursor to the end of the line |
| `Tab` | Completion menu — arrows or `Tab` move, `Enter` picks. Case-insensitive: `doc` finds `Documents` |
| `Esc` | Go to Normal mode |

### Normal mode (after `Esc`)

| Key | What it does |
|---|---|
| `i` / `a` | Back to Insert mode, before / after the cursor |
| `I` / `A` | Insert at the start / end of the line |
| `h` `l` `w` `b` `e` `0` `$` | Move, as in Vim |
| `x` `dw` `dd` `cw` `cc` `C` `S` | Delete / change, as in Vim |
| `u` | Undo |
| `v` / `V` | Select characters / the whole line |
| **`vv`** | **Open the command in Neovim** — for long commands; save and quit to come back |
| `ci"` `di(` `ya{` | Change / delete / yank inside or around quotes and brackets |
| `cs"'` | Change the surrounding `"` into `'` |
| `ds"` | Delete the surrounding `"` |
| `S"` on a selection | Wrap the selection in `"` |
| `Ctrl+A` / `Ctrl+X` | Increase / decrease the number under the cursor |

⚠️ There is no redo key. Vim's `Ctrl+R` is taken by fzf's history search (see *History*).

---

## Copy and paste

| Key | Mode | What it does |
|---|---|---|
| `yy` / `y` + motion | Normal | Yank — into the tmux buffer that **every pane shares**, and on to the system clipboard |
| `p` / `P` | Normal | Paste that shared buffer after / before the cursor |
| The terminal's own paste — `Cmd+V` on the Mac, right-click or `Ctrl+Shift+V` on Windows | Insert | Paste what you copied in a browser or another app |

Inside tmux, `p` reads the tmux buffer, not the system clipboard — so text copied in a browser comes
in through the terminal's paste, never through `p`. The full story is in `README.md` → *Shared clipboard*.

---

## History

| Key | Mode | What it does |
|---|---|---|
| **`↑` / `↓`** | Insert | Step through past commands that **contain** what you have typed so far |
| **`Ctrl+R`** | **Normal** | **fzf history** — fuzzy-search every command ever run, `Enter` picks one |
| `Ctrl+R` | Insert | zsh's plain backward search — type, press `Ctrl+R` again for older matches |

⚠️ **The fzf history answers only in Normal mode.** zsh-vi-mode claims `Ctrl+R` in Insert mode for
zsh's own search. So: `Esc`, then `Ctrl+R`.

---

## Suggestions — the grey text after the cursor

zsh-autosuggestions proposes the rest of the line from your history.

| Key | What it does |
|---|---|
| `→` or `Ctrl+E` | Accept the whole suggestion |
| `Ctrl+→` | Accept just the next word |
| `Ctrl+\` | Turn suggestions off / on — handy for screen recordings |

---

## Finding files — fzf

| Key | What it does |
|---|---|
| **`Ctrl+T`** | **Pick a file** below the current folder — files only, no hidden files; `Enter` pastes the path onto the command line |
| `Ctrl+F` | The same, but **files and folders**, hidden included |
| `Alt+C` | Pick a folder below this one and `cd` into it |
| `v **` then `Tab` | Open the file picker in the middle of any command — here, to open in Neovim |
| `cd **` then `Tab` | The same, listing folders (also after `pushd` and `rmdir`) |

What `Ctrl+T` and `Ctrl+F` leave out: anything `.gitignore` excludes — `.env`, `node_modules` and
build output, usually. That is deliberate. Reach those with `fd -u` or `rg -uu`, below — or `cd` into
the folder first (`cd node_modules`, then `Ctrl+T`), since a `.gitignore` above no longer hides it.

⚠️ `Ctrl+F` **does** list what is inside `.git/` — it includes hidden files, and fd only skips what
`.gitignore` names (never `.git` itself). `Ctrl+T` skips `.git/` on its own, being hidden. Type
`!.git/` to filter it out of `Ctrl+F`.

They search the folder the shell is in. From `~` that is close to a million files — `cd` into the
project first.

### Inside the fzf window

| Key | What it does |
|---|---|
| `Ctrl+J` / `Ctrl+K` or `↓` / `↑` | Move down / up (tmux passes `Ctrl+J/K` through to fzf) |
| `Tab` / `Shift+Tab` | Mark / unmark several files — `Ctrl+T` only |
| `Enter` | Accept |
| `Esc` or `Ctrl+C` | Cancel |
| `Shift+↑` / `Shift+↓` | Scroll the preview |
| `Ctrl+U` | Clear what you typed |

### Search syntax — fzf, and Telescope in Neovim too

| Type | Matches |
|---|---|
| `abc` | fuzzy — `a`, `b`, `c` in that order, gaps allowed |
| `'abc` | exactly `abc`, somewhere |
| `^abc` / `abc$` | starts with / ends with `abc` — `.html$` keeps only HTML files |
| `!abc` | does **not** contain `abc` |
| `abc def` | both terms (fzf only) |
| `abc \| def` | either term (fzf only) |

---

## Searching inside files — ripgrep

`rg` searches the current folder and everything below it. `grep` is an alias for `rg`.

| Command | What it does |
|---|---|
| **`rg "word"`** | **Every line containing `word`**, grouped by file |
| **`rg -l "word"`** | **Only the names** of the files that contain it |
| `rg -i "word"` | Ignore upper / lower case |
| `rg -w "word"` | Whole word only — `cat` will not match `category` |
| `rg -F "a.b(c)"` | Take the text literally, not as a regex |
| `rg -g '*.html' "word"` | Only in files whose name matches the pattern |
| `rg -t py "word"` | Only in one language's files (`rg --type-list` for the names) |
| `rg -C 2 "word"` | Two lines of context around each hit |
| `rg -c "word"` | How many matching lines each file has |
| `rg "word" some/dir` | Search a different folder |
| `rg --hidden "word"` | Include hidden files (`.env`, `.github/` …) |
| `rg -uu "word"` | Include hidden **and** `.gitignore`d files — `node_modules`, build output, `.env` |

What `rg` skips by default: hidden files, anything `.gitignore` excludes, and binary files. Each `-u`
lifts one layer: `-u` ignores `.gitignore`, `-uu` adds hidden files, `-uuu` adds binary files too.

---

## Finding files by name — fd

| Command | What it does |
|---|---|
| **`fd name`** | Files and folders whose name contains `name` |
| `fd -e html` | Every file with that extension |
| `fd -t d name` | Folders only |
| `fd -H name` | Include hidden files |
| `fd -u name` | Include hidden **and** `.gitignore`d files |
| `fd name some/dir` | Search a different folder |

---

## Moving around

| Command / key | What it does |
|---|---|
| **`z keyword`** | **Jump to the folder you use most** whose path matches `keyword` (zoxide) |
| `zi` | Pick from your most-used folders in a list |
| `z` | Home |
| `-` or `z -` | Back to the previous folder |
| A folder's name, alone | `cd` into it — no need to type `cd` |
| `Alt+C` | Pick a folder below this one |
| `lf` | A file manager — quit with `q` and the shell stays in the folder you ended up in |

Inside `lf`: `h` `j` `k` `l` move (`h` up a folder, `l` opens) · `gg` / `G` top / bottom ·
`/` search, `n` / `N` next / previous match · `y` `d` `p` copy / cut / paste · `c` clears the
copy / cut · `q` quits.

---

## Listing and reading files

| Command | What it does |
|---|---|
| `ls` | List, with icons (eza) |
| `ll` | Detailed list, with each file's git status |
| `la` | The same, hidden files included |
| `tree` | Tree view |
| `cat file` | Show a file with syntax colours (bat) |
| `v file` | Open it in Neovim |

## Git shortcuts

| Command | What it does |
|---|---|
| `glog` | `git log`, without trapping short output in the pager |
| `gadog` | Every branch as a graph, one line per commit |

---

## Config and upkeep

| Command | What it does |
|---|---|
| **`exec zsh`** | **Reload the config in this shell** |
| `zplugin-update` | Update the four zsh plugins |
| `~/.config/zsh/local.zsh` | Settings for this machine only — not tracked by git |
| `zsh -x -i -c exit 2>&1 \| tail -40` | See the last lines zsh ran before a startup error |

⚠️ **A config change never reaches a shell that is already open.** zsh reads its config once, when
it starts. After a `git pull` or an edit here, run `exec zsh` in each open shell and tmux pane — or
open a new one. A long-lived tmux pane can otherwise keep the old settings for days.
