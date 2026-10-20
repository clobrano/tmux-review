#!/usr/bin/env bash
# Prints the setup shown at the start of the demo recording.
r=$'\e[0m' b=$'\e[1m' gray=$'\e[90m' green=$'\e[32m' blue=$'\e[34m' yellow=$'\e[33m' mauve=$'\e[38;2;203;166;247m'
cat <<CARD
${b}${mauve}tmux-review${r} ${b}— review a tmux pane in Neovim, send comments back to the agent${r}

${gray}# ~/.tmux.conf: prefix + r opens the review popup${r}
${blue}bind${r} r display-popup -EE -w 95% -h 95% ${green}"~/Apps/tmux-review/bin/tmux-review"${r}

${gray}-- Neovim: Review.nvim adds comments, tmux-review pastes them into the pane${r}
${yellow}require${r}(${green}"review"${r}).setup({ ... })
vim.keymap.set({ ${green}"n"${r}, ${green}"v"${r} }, ${green}"<leader>rn"${r}, ${green}":Review note<cr>"${r})
${yellow}require${r}(${green}"tmux_review"${r}).configure_tmux_review()  ${gray}-- adds <leader>rt${r}

${b}In the popup${r}
  ${b}<leader>rn${r}  comment on a line or a visual selection
  ${b}<leader>rt${r}  paste all comments into the agent's prompt and close
CARD
