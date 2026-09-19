# ~/.config/zsh/prompt.zsh

# Prevent Python virtualenv from polluting the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

FUNCNEST=100


# Starship's directory module has no length cap, so the path is built here and shown by
# starship.toml's env_var.PROMPT_DIR: the last two folders, and once the pair passes 25
# characters the parent is cut short with … (dropped if the folder alone leaves no room).
_prompt_dir() {
  local p=${(%):-%2~} parent leaf n
  if (( ${#p} > 25 )) && [[ $p == ?*/* ]]; then
    parent=${p%/*} leaf=${p##*/}
    n=$(( 25 - ${#leaf} - 2 ))    # room left for the parent after "…" and "/"
    if (( n >= 3 )); then p="${${parent[1,n]}% }…/$leaf"; else p=$leaf; fi
  fi
  [[ $p == [~/]* ]] || p="…/$p"   # anything not rooted at ~ or / had folders cut off
  export PROMPT_DIR=$p
}
precmd_functions+=(_prompt_dir)
