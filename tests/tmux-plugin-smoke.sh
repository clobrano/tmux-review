#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/bin/tmux" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  show-option)
    option=${!#}
    case "$option" in
      @tmux-review-agent-key) printf '%s\n' "${TMUX_REVIEW_TEST_AGENT_KEY:-}" ;;
      @tmux-review-comment-key) printf '%s\n' "${TMUX_REVIEW_TEST_COMMENT_KEY:-}" ;;
      @tmux-review-review-key) printf '%s\n' "${TMUX_REVIEW_TEST_REVIEW_KEY:-}" ;;
      @tmux-review-agent-command) printf '%s\n' "${TMUX_REVIEW_TEST_AGENT_COMMAND:-}" ;;
      *) printf 'unexpected option: %s\n' "$option" >&2; exit 2 ;;
    esac
    ;;
  bind-key)
    printf 'CALL\t' >> "$TMUX_REVIEW_TEST_BINDINGS"
    printf '%s\t' "$@" >> "$TMUX_REVIEW_TEST_BINDINGS"
    printf '\n' >> "$TMUX_REVIEW_TEST_BINDINGS"
    ;;
  *) printf 'unexpected tmux command: %s\n' "$1" >&2; exit 2 ;;
esac
MOCK
chmod +x "$tmp/bin/tmux"
export PATH="$tmp/bin:$PATH"
export TMUX_REVIEW_TEST_BINDINGS="$tmp/bindings"

assert_binding() {
  local key=$1 command=$2 value=$3
  awk -F '\t' -v key="$key" -v command="$command" -v value="$value" \
    '$1 == "CALL" && $2 == "bind-key" && $3 == key && $4 == command && index($0, value) { found = 1 }
     END { exit !found }' "$TMUX_REVIEW_TEST_BINDINGS"
}

assert_no_binding() {
  local key=$1
  awk -F '\t' -v key="$key" \
    '$1 == "CALL" && $2 == "bind-key" && $3 == key { found = 1 }
     END { exit found }' "$TMUX_REVIEW_TEST_BINDINGS"
}

(cd "$tmp" && "$repo/tmux-review.tmux")
assert_binding r display-popup "$repo/bin/tmux-review"
assert_binding c send-keys "$repo/bin/tmux-comment"
assert_binding a if-shell '#{==:#{pane_current_command},codex}'

: > "$TMUX_REVIEW_TEST_BINDINGS"
(
  export TMUX_REVIEW_TEST_AGENT_KEY=z
  export TMUX_REVIEW_TEST_COMMENT_KEY=C
  export TMUX_REVIEW_TEST_REVIEW_KEY=R
  export TMUX_REVIEW_TEST_AGENT_COMMAND='claude --continue'
  cd "$tmp"
  "$repo/tmux-review.tmux"
)
assert_binding R display-popup "$repo/bin/tmux-review"
assert_binding C send-keys "$repo/bin/tmux-comment"
assert_binding z split-window 'claude --continue'
assert_no_binding r
assert_no_binding c
assert_no_binding a
printf 'tmux plugin smoke test passed\n'
