#!/bin/bash
# caffeinate.sh — bật/tắt caffeinate, hỗ trợ hẹn giờ, tách hoàn toàn khỏi phiên
# (nohup + disown) để không bị kill khi phiên/job Claude Code rotate.
set -euo pipefail

STATE_DIR="$HOME/.claude/skills/caffeinate"
PID_FILE="$STATE_DIR/schedule.pid"
mkdir -p "$STATE_DIR"

usage() {
  cat <<'EOF'
Cách dùng:
  caffeinate.sh on                      Bật ngay, giữ máy không ngủ tới khi tắt
  caffeinate.sh on --for <giây>         Bật ngay, tự TẮT sau N giây
  caffeinate.sh off                     Tắt ngay
  caffeinate.sh off --after <giây>      Hẹn TẮT sau N giây
  caffeinate.sh sleep --after <giây>    Hẹn tắt caffeinate + cho máy NGỦ THẬT sau N giây
  caffeinate.sh cancel                  Hủy lịch hẹn đang chờ (nếu có)
  caffeinate.sh status                  Xem trạng thái hiện tại
EOF
}

target_time() {
  local secs="$1"
  date -v+"${secs}"S '+%H:%M:%S' 2>/dev/null || date -d "+${secs} seconds" '+%H:%M:%S' 2>/dev/null || echo "?"
}

start_now() {
  if pgrep -f "caffeinate -dims" > /dev/null 2>&1; then
    echo "caffeinate đã đang chạy rồi (PID $(pgrep -f 'caffeinate -dims' | head -1))."
    return
  fi
  nohup caffeinate -dims > /dev/null 2>&1 &
  disown
  sleep 0.3
  echo "Đã bật caffeinate (PID $(pgrep -f 'caffeinate -dims' | head -1)) — máy sẽ không ngủ tới khi tắt."
}

stop_now() {
  if pgrep -x caffeinate > /dev/null 2>&1; then
    killall caffeinate 2>/dev/null || true
    echo "Đã tắt caffeinate."
  else
    echo "Không có caffeinate nào đang chạy."
  fi
}

cancel_schedule() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      echo "Đã hủy lịch hẹn đang chờ (PID $pid)."
    else
      echo "Lịch hẹn trước đó đã chạy xong hoặc không còn tồn tại."
    fi
    rm -f "$PID_FILE"
  else
    echo "Không có lịch hẹn nào đang chờ."
  fi
}

schedule() {
  # $1 = giây, $2 = lệnh sẽ chạy sau khi sleep xong
  local secs="$1" cmd="$2"
  cancel_schedule > /dev/null
  nohup bash -c "sleep $secs; $cmd" > /dev/null 2>&1 &
  local pid=$!
  disown
  echo "$pid" > "$PID_FILE"
  echo "Đã hẹn giờ — sẽ thực hiện lúc khoảng $(target_time "$secs") (PID lịch hẹn: $pid)."
}

status() {
  if pgrep -x caffeinate > /dev/null 2>&1; then
    echo "caffeinate ĐANG chạy:"
    pgrep -lx caffeinate
  else
    echo "caffeinate KHÔNG chạy."
  fi
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Có lịch hẹn đang chờ (PID $(cat "$PID_FILE"))."
  fi
}

case "${1:-}" in
  on)
    if [[ "${2:-}" == "--for" && -n "${3:-}" ]]; then
      start_now
      schedule "$3" "killall caffeinate 2>/dev/null"
    else
      start_now
    fi
    ;;
  off)
    if [[ "${2:-}" == "--after" && -n "${3:-}" ]]; then
      schedule "$3" "killall caffeinate 2>/dev/null"
    else
      stop_now
    fi
    ;;
  sleep)
    if [[ "${2:-}" == "--after" && -n "${3:-}" ]]; then
      schedule "$3" "killall caffeinate 2>/dev/null; pmset sleepnow"
    else
      usage
      exit 1
    fi
    ;;
  cancel)
    cancel_schedule
    ;;
  status)
    status
    ;;
  *)
    usage
    exit 1
    ;;
esac
