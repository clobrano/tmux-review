#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/bin/tmux" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
command=$1
shift
case "$command" in
  capture-pane) printf 'captured pane output\n' ;;
  display)
    case " $* " in
      *'#{window_panes}'*) printf '1\n' ;;
      *) exit 2 ;;
    esac
    ;;
  load-buffer) cp "${!#}" "$TMUX_REVIEW_TEST_PASTE" ;;
  paste-buffer) printf '%s\n' "$*" > "$TMUX_REVIEW_TEST_ARGS" ;;
  *) printf 'unexpected tmux command: %s\n' "$command" >&2; exit 2 ;;
esac
MOCK
cat > "$tmp/bin/mock-editor" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == --wait ]]
file=${@: -1}
awk 'NR == 1 { print; print "Please inspect the reset path."; next } { print }' "$file" > "$file.tmp"
mv "$file.tmp" "$file"
MOCK
cat > "$tmp/bin/git" <<'MOCK'
#!/usr/bin/env bash
printf 'Git should not be needed for a non-Neovim editor\n' >&2
exit 1
MOCK
chmod +x "$tmp/bin/tmux" "$tmp/bin/mock-editor" "$tmp/bin/git"

export PATH="$tmp/bin:$PATH"
export XDG_STATE_HOME="$tmp/state"
export VISUAL='mock-editor --wait'
export TMUX_REVIEW_TEST_PASTE="$tmp/pasted"
export TMUX_REVIEW_TEST_ARGS="$tmp/paste-args"
"$repo/bin/tmux-review" %1

[[ "$(<"$TMUX_REVIEW_TEST_PASTE")" == 'Please inspect the reset path.' ]]
grep -Fq 'captured pane output' "$tmp/state/tmux-review/"*.log
grep -Fq -- '-t %1' "$TMUX_REVIEW_TEST_ARGS"
[[ ! -d "$tmp/state/tmux-review/.git" ]]
printf 'tmux-review smoke test passed\n'
