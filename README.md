# tmux-review

Review the current tmux pane in Neovim while keeping its ANSI colors and text styles visible. The package captures pane output, writes a plain-text review log, and applies highlights in Neovim.

The package contains:

- `bin/tmux-review`: captures the pane and opens the review buffer.
- `lua/tmux_ansi.lua`: converts ANSI styles into Neovim highlights.

The raw ANSI capture is temporary. The review log contains plain text, so annotation line numbers and exported excerpts stay readable.

## Requirements

- tmux with `capture-pane -e` support
- Bash
- Neovim

The tmux capture and ANSI rendering work without Review.nvim. Review.nvim is optional and adds annotations and comment export.

## Install the Neovim module with lazy.nvim

After publishing the repo, clone it where you want to keep it:

~~~sh
git clone https://github.com/clobrano/tmux-review.git ~/Apps/tmux-review
~~~

Add a plugin spec at `lua/plugins/tmux-review.lua` in your Neovim config.

For a local checkout:

~~~lua
return {
  dir = vim.fn.expand("~/Apps/tmux-review"),
  name = "tmux-review",
  lazy = true,
}
~~~

After publishing the repo, use its GitHub slug instead:

~~~lua
return {
  "clobrano/tmux-review",
  lazy = true,
}
~~~

Then run `:Lazy sync`. Lazy.nvim loads the Lua module when it is required. The tmux launcher also adds its checkout to Neovim's runtime path, so the popup can load the renderer directly.

## Add the tmux binding

Add this to `~/.tmux.conf`, adjusting the path if the repo is elsewhere:

~~~tmux
bind r display-popup -EE -w 95% -h 95% "$HOME/Apps/tmux-review/bin/tmux-review"
~~~

Reload the tmux config, then press the tmux prefix followed by `r`.

The helper stores plain-text review logs under `$XDG_STATE_HOME/tmux-review`, or `~/.local/state/tmux-review` when that variable is unset. It removes the temporary ANSI capture when Neovim exits.

## Optional: add annotations with Review.nvim

Install Review.nvim separately. Add a Review.nvim spec to your Neovim config and use a setup like this:

~~~lua
return {
  "georgeguimaraes/review.nvim",
  version = "*",
  dependencies = {
    "esmuellert/codediff.nvim",
    "MunifTanjim/nui.nvim",
  },
  event = "VeryLazy",
  config = function()
    local pane = vim.env.TMUX_REVIEW_PANE

    require("review").setup({
      comment_types = {
        note = { key = "q", name = "Question", icon = "🙋", hl = "DiagnosticInfo" },
        suggestion = { key = "a", name = "Action", icon = "💡", hl = "DiagnosticHint" },
        issue = { key = "i", name = "Issue", icon = "⚠️", hl = "DiagnosticError" },
        praise = { key = "p", name = "Praise", icon = "✨", hl = "DiagnosticOk" },
      },
      export = {
        clipboard = pane == nil,
        on_export = function(_, comments)
          local feedback = {
            "Feedback on the previous output. Use each comment and its source location.",
            "",
          }

          local labels = { note = "QUESTION", suggestion = "ACTION" }
          for i, comment in ipairs(comments) do
            local label = labels[comment.type] or comment.type:upper()
            table.insert(feedback, ("%d. **[%s]** %s"):format(i, label, comment.text))
            table.insert(feedback, ("   Source file: %s:%d"):format(comment.file, comment.line))
          end

          local output = table.concat(feedback, "\n")
          vim.fn.setreg("+", output)
          if pane == nil then vim.fn.setreg("*", output) end
        end,
      },
    })
  end,
}
~~~

The launcher sets `TMUX_REVIEW_PANE` while running in the popup. The example uses it to copy exported comments to the system clipboard.

## Supported ANSI styles

The renderer supports standard and bright colors, 256-color and RGB foreground/background colors, bold, italic, underline, reverse, and strikethrough.
