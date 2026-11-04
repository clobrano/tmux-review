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
  copy-mode|display-popup) ;;
  load-buffer) cp "${!#}" "$TMUX_REVIEW_TEST_BUFFER" ;;
  display) printf '%s\n' '%0' ;;
  display-panes) printf '%s\n' "$*" > "$TMUX_REVIEW_TEST_DISPLAY_PANES" ;;
  delete-buffer) rm -f "$TMUX_REVIEW_TEST_BUFFER" ;;
  paste-buffer) printf '%s\n' "$*" >> "$TMUX_REVIEW_TEST_PASTE_ARGS" ;;
  *) printf 'unexpected tmux command: %s\n' "$command" >&2; exit 2 ;;
esac
MOCK
cat > "$tmp/bin/mock-editor" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
MOCK
chmod +x "$tmp/bin/tmux" "$tmp/bin/mock-editor"

export PATH="$tmp/bin:$PATH"
export VISUAL=mock-editor
export TMUX_REVIEW_TEST_BUFFER="$tmp/tmux-buffer"
export TMUX_REVIEW_TEST_DISPLAY_PANES="$tmp/display-panes"
export TMUX_REVIEW_TEST_PASTE_ARGS="$tmp/paste-args"
printf 'selected output\n' | "$repo/bin/tmux-comment" %0 2

grep -Fq -- "paste-buffer -p -r -d -b tmux-review-comment -t '%%'" "$TMUX_REVIEW_TEST_DISPLAY_PANES"
[[ -s "$TMUX_REVIEW_TEST_BUFFER" ]]
grep -Fxq '> selected output' "$TMUX_REVIEW_TEST_BUFFER"
printf 'tmux comment smoke test passed\n'
