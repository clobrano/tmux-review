# Records the tmux-review demo GIF.
# Run from the repository root: vhs demo/demo.tape
# Requires vhs, ttyd, ffmpeg, tmux and nvim on PATH.

Output demo/tmux-review.gif

Require tmux
Require nvim

Set Shell "bash"
Set FontSize 16
Set Width 1200
Set Height 700
Set Padding 16
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

# Start an isolated tmux server so the user's config and sessions stay untouched.
Hide
Type "export TMUX_REVIEW_ROOT=$PWD XDG_STATE_HOME=$(mktemp -d)" Enter
Type "tmux -L tmux-review-demo -f demo/tmux.conf new-session -s demo" Enter
Sleep 1s
Type "clear" Enter
Show

# Produce some colorful output in the pane.
Type "./demo/sample-output.sh"
Sleep 500ms
Enter
Sleep 2s

# prefix + r opens the review popup with the pane's colors preserved.
Ctrl+b
Type "r"
Sleep 2.5s

# Move around the captured output like any Neovim buffer.
Type "gg"
Sleep 500ms
Type "/keeps"
Sleep 300ms
Enter
Sleep 1s
Type "V"
Sleep 300ms
Type "jj"
Sleep 1.5s
Escape
Type "G"
Sleep 1.5s

# Close the popup and return to the pane.
Type ":q"
Sleep 300ms
Enter
Sleep 1.5s

Hide
Type "tmux -L tmux-review-demo kill-server" Enter
