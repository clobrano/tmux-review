# Records the tmux-review demo GIF.
# Run from the repository root: ./demo/setup.sh && vhs demo/demo.tape
# Requires vhs, ttyd, ffmpeg, tmux, git and nvim on PATH.

Output demo/tmux-review.gif

Require tmux
Require nvim

Set Shell "bash"
Set FontSize 15
Set Width 1280
Set Height 760
Set Padding 16
Set Theme "Catppuccin Mocha"
Set TypingSpeed 60ms

# Start an isolated tmux server with the demo configs, so yours stay untouched.
Hide
Type "export TMUX_REVIEW_ROOT=$PWD XDG_CONFIG_HOME=$PWD/demo/config XDG_STATE_HOME=$(mktemp -d) XDG_DATA_HOME=$(mktemp -d)" Enter
Type "tmux -L tmux-review-demo kill-server 2>/dev/null; tmux -L tmux-review-demo -f demo/tmux.conf new-session -s demo" Enter
Sleep 1s
Type "clear; ./demo/intro.sh" Enter
Sleep 500ms
Show

# The setup: a tmux binding and two lines of Neovim config.
Sleep 7s

# An AI agent finishes a run and waits for feedback.
Hide
Type "clear; ./demo/fake-agent.sh" Enter
Sleep 500ms
Show
Sleep 3s

# prefix + r opens the pane in Neovim, colors included.
Ctrl+b
Sleep 1s
Type "r"
Sleep 2.5s

# Select the failing assertions and ask a question about them.
Type "/keeps"
Sleep 300ms
Enter
Sleep 800ms
Type "Vj"
Sleep 1s
Type " rn"
Sleep 1.5s
Type "Why is bold lost after a partial reset?"
Sleep 800ms
Escape
Sleep 300ms
Enter
Sleep 1.5s

# Comment on another line, switching the comment type with Tab.
Type "/index"
Sleep 300ms
Enter
Sleep 800ms
Type " rn"
Sleep 1s
Tab
Sleep 600ms
Type "Use the xterm 256-color table here."
Sleep 800ms
Escape
Sleep 300ms
Enter
Sleep 2s

# <leader>rt pastes the comments, with the quoted lines, into the agent prompt.
Type " rt"
Sleep 4s

Hide
Ctrl+c
Type "tmux -L tmux-review-demo kill-server" Enter
