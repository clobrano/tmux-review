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
Type "export TMUX_REVIEW_ROOT=$PWD XDG_CONFIG_HOME=$PWD/demo/config XDG_STATE_HOME=$(mktemp -d) XDG_DATA_HOME=$(mktemp -d) VISUAL=nvim" Enter
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

# prefix + a opens another agent split.
Ctrl+b
Sleep 1s
Type "a"
Sleep 2s

# Select the left pane, then enter copy mode.
Ctrl+b
Sleep 300ms
Type "q"
Sleep 500ms
Type "0"
Sleep 500ms
Ctrl+b
Sleep 300ms
Type "["
Sleep 500ms

# Select the failing assertions and add a note from tmux.
Type "/keeps"
Sleep 300ms
Enter
Sleep 800ms
Type "Vj"
Sleep 1s
Ctrl+b
Sleep 1s
Type "c"
Sleep 2.5s

# Write the note below the quoted selection.
Type "G"
Sleep 300ms
Type "o"
Sleep 300ms
Type "Please check the partial reset path."
Sleep 800ms
Escape
Sleep 300ms
Type ":wq"
Sleep 300ms
Enter
Sleep 2s

# Choose the right pane, then return to the left pane.
Type "1"
Sleep 2s
Ctrl+b
Sleep 300ms
Type "q"
Sleep 500ms
Type "0"
Sleep 500ms

# prefix + r opens the pane in Neovim with its ANSI colors.
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

# <leader>rt pastes the comments, with the quoted lines, into the right pane.
Type " rt"
Sleep 1.5s
Enter
Sleep 500ms
Enter
Sleep 4s

Hide
Ctrl+c
Type "tmux -L tmux-review-demo kill-server" Enter
