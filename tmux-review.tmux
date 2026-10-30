#!/usr/bin/env bash
set -euo pipefail
plugin_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

tmux_option() {
  tmux show-option -gqv "$1" 2>/dev/null || true
}

agent_key="$(tmux_option @tmux-review-agent-key)"
comment_key="$(tmux_option @tmux-review-comment-key)"
review_key="$(tmux_option @tmux-review-review-key)"
agent_command="$(tmux_option @tmux-review-agent-command)"
agent_key="${agent_key:-a}"
comment_key="${comment_key:-c}"
review_key="${review_key:-r}"

if [[ -n "$agent_command" ]]; then
  tmux bind-key "$agent_key" split-window -h -l 40% -c '#{pane_current_path}' "$agent_command"
else
  tmux bind-key "$agent_key" if-shell -F '#{==:#{pane_current_command},codex}' \
    'split-window -h -l 40% -c "#{pane_current_path}" "codex fork --last"' \
    'split-window -h -l 40% -c "#{pane_current_path}" "pi --continue"'
fi

tmux bind-key "$comment_key" send-keys -X copy-pipe-no-clear \
  "$plugin_root/bin/tmux-comment '#{pane_id}' '#{window_panes}'"
tmux bind-key "$review_key" display-popup -EE -w 95% -h 95% \
  "$plugin_root/bin/tmux-review"
