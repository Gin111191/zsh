# ~/.config/zsh/.zprofile
# Khi ZDOTDIR được set, zsh đọc file này THAY CHO ~/.zprofile (chạy 1 lần, lúc login).

# ---------- Homebrew ----------
# Dò cả ba vị trí: Apple Silicon, Intel Mac, Linuxbrew. Guard HOMEBREW_PREFIX để
# không chạy lại khi shell login lồng nhau (tmux, ssh vào chính máy) — chạy hai lần
# là PATH có mục trùng.
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$_brew" ]]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi

# ---------- Lối thoát cho trình cài đặt ----------
# ZDOTDIR làm ~/.zprofile không còn được zsh đọc. Nhiều installer (nvm, conda, rustup…)
# vẫn ghi thẳng vào đó và sẽ im lặng không có tác dụng. Nạp lại ở đây để chúng vẫn chạy.
[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
