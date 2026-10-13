local M = {}

local configured = false

local function notify(message, level)
  vim.notify(message, level, { title = "tmux-review" })
end

local function paste_to_pane(pane, markdown)
  local result = vim.fn.system({ "tmux", "load-buffer", "-" }, markdown)
  if vim.v.shell_error ~= 0 then
    notify("Could not load review into tmux: " .. result, vim.log.levels.ERROR)
    return false
  end

  result = vim.fn.system({ "tmux", "paste-buffer", "-p", "-r", "-t", pane })
  if vim.v.shell_error ~= 0 then
    notify("Could not paste review into tmux: " .. result, vim.log.levels.ERROR)
    return false
  end

  return true
end

local function excerpt(comment)
  local ok, lines = pcall(vim.fn.readfile, comment.file)
  if not ok or comment.line == 0 then return {} end

  local first = math.max(comment.line, 1)
  local last = math.max(first, comment.line_end or first)
  local fence_length = 3

  for i = first, last do
    for run in (lines[i] or ""):gmatch("~+") do
      fence_length = math.max(fence_length, #run + 1)
    end
  end

  local fence = string.rep("~", fence_length)
  local filetype = vim.filetype.match({ filename = comment.file }) or "text"
  local out = { fence .. filetype }
  for i = first, last do table.insert(out, lines[i] or "") end
  table.insert(out, fence)
  return out
end

local function location(comment)
  local path = comment.file
  local root = require("review.utils").git_root()
  if root and not path:match("^/") then
    path = root .. "/" .. path
  end
  path = vim.fn.fnamemodify(path, ":p")

  if comment.line and comment.line > 0 then
    path = path .. ":" .. comment.line
    if comment.line_end and comment.line_end > comment.line then
      path = path .. "-" .. comment.line_end
    end
  end

  return path
end

local function format_comments(comments)
  local markdown = {
    "Feedback on your previous output. Review each comment with its quoted context.",
    "Reply to QUESTION comments without changing code. Make changes for ACTION or ISSUE comments. Treat PRAISE as positive feedback.",
    "",
  }
  local type_labels = { note = "QUESTION", suggestion = "ACTION" }

  for i, comment in ipairs(comments or {}) do
    local type_name = type_labels[comment.type] or comment.type:upper()
    table.insert(markdown, ("%d. **[%s]** %s\n   Source file: `%s`"):format(
      i, type_name, comment.text, location(comment)
    ))
    vim.list_extend(markdown, excerpt(comment))
  end

  return table.concat(markdown, "\n")
end

function M.configure_tmux_review()
  local pane = vim.env.TMUX_REVIEW_PANE
  if not pane or configured then return end

  local ok, review_config = pcall(require, "review.config")
  if not ok or type(review_config.get) ~= "function" then
    notify("Set up Review.nvim before configuring tmux review handoff", vim.log.levels.WARN)
    return
  end

  local options = review_config.get()
  options.export = options.export or {}
  local on_export = options.export.on_export
  local send_to_pane = false

  options.export.on_export = function(markdown, comments)
    if on_export then
      local callback_ok, err = pcall(on_export, markdown, comments)
      if not callback_ok then
        notify("Review.nvim export callback failed: " .. tostring(err), vim.log.levels.ERROR)
      end
    end

    if send_to_pane and paste_to_pane(pane, format_comments(comments)) then
      vim.schedule(function()
        local close_ok, close_err = pcall(vim.cmd, "qa")
        if not close_ok then notify(close_err, vim.log.levels.ERROR) end
      end)
    end
  end

  vim.keymap.set("n", "<leader>rt", function()
    send_to_pane = true
    local export_ok, err = pcall(function() require("review").export() end)
    send_to_pane = false
    if not export_ok then notify(err, vim.log.levels.ERROR) end
  end, { desc = "Export review and return to tmux prompt" })

  configured = true
end

return M
