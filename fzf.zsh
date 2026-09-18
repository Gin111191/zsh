# =========================================================
# fzf
# =========================================================

# Both pick files AND folders (no --type restriction). The only difference between them is
# --hidden. General default — also feeds `**<Tab>` completion (v **, cd **).
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix'  # strip-cwd-prefix removes the leading ./ from results

# Ctrl+T: the same, without hidden files. Its own command, not derived from
# FZF_DEFAULT_COMMAND, so it keeps excluding hidden files no matter what the default becomes.
export FZF_CTRL_T_COMMAND='fd --strip-cwd-prefix'

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

# bat can only preview a file; it exits non-zero on a folder. Both keys can land on a folder
# now, so both previews fall back to `eza -la` when bat fails.
export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {} 2>/dev/null || eza -la --color=always --icons=always {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: everything FZF_DEFAULT_COMMAND lists — files AND folders, hidden included.
_fzf_file_dir_hidden() {
  local result
  result=$(eval "${FZF_DEFAULT_COMMAND:-find . -not -path '*/.*'}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}
zle -N _fzf_file_dir_hidden
