-- Neovim config used only by demo.tape: Review.nvim plus an on-screen key display.
vim.g.mapleader = " "
vim.o.termguicolors = true
vim.o.laststatus = 2
vim.o.cmdheight = 1

local plugins = vim.fn.fnamemodify(vim.env.MYVIMRC, ":h:h:h") .. "/.plugins"
for _, name in ipairs({ "nui.nvim", "codediff.nvim", "review.nvim" }) do
  vim.opt.rtp:append(plugins .. "/" .. name)
end

-- The part a real config needs: Review.nvim, a note key, and the tmux handoff.
require("review").setup({
  comment_types = {
    note = { key = "q", name = "Question", icon = "?", hl = "DiagnosticInfo" },
    suggestion = { key = "a", name = "Action", icon = ">", hl = "DiagnosticHint" },
    issue = { key = "i", name = "Issue", icon = "!", hl = "DiagnosticError" },
    praise = { key = "p", name = "Praise", icon = "+", hl = "DiagnosticOk" },
  },
  export = { clipboard = false },
})
vim.keymap.set({ "n", "v" }, "<leader>rn", ":Review note<cr>", { desc = "Review: note here" })
require("tmux_review").configure_tmux_review()

-- Key display for the recording: shows the keys typed outside insert mode and what they do.
local captions = {
  ["<leader> r n"] = "Review.nvim: comment on the selection",
  ["<leader> r t"] = "tmux-review: paste comments into the agent pane",
  ["Tab"] = "Review.nvim: switch the comment type",
  ["Esc Enter"] = "Review.nvim: save the comment",
  ["V j"] = "select lines",
  ["/"] = "search",
}
local buf = vim.api.nvim_create_buf(false, true)
local win, keys, timer = nil, {}, vim.uv.new_timer()

local function render()
  local seq = table.concat(keys, " ")
  local caption
  for pattern, text in pairs(captions) do
    if seq:sub(-#pattern) == pattern then caption = text end
  end
  local lines = { "", "  " .. seq .. "  " }
  if caption then table.insert(lines, "  " .. caption .. "  ") end
  table.insert(lines, "")
  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_add_highlight(buf, -1, "Bold", 1, 0, -1)
  local opts = {
    relative = "editor", anchor = "NE", row = 1, col = vim.o.columns - 2,
    width = width, height = #lines, style = "minimal", border = "rounded",
    title = " keys ", title_pos = "center", focusable = false, zindex = 300,
  }
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_config(win, opts)
  else
    win = vim.api.nvim_open_win(buf, false, opts)
    vim.wo[win].winhighlight = "Normal:Search,FloatBorder:Search,FloatTitle:Search"
  end
end

local function hide()
  keys = {}
  if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  win = nil
end

local names = { ["<Space>"] = "<leader>", ["<CR>"] = "Enter", ["<Esc>"] = "Esc", ["<Tab>"] = "Tab" }

vim.on_key(function(_, typed)
  if not typed or typed == "" then return end
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("^c") then return end
  -- Splits "<Space>rn" into "<Space>", "r", "n"; skips comment text typed in insert mode.
  local new, rest = {}, vim.fn.keytrans(typed)
  while rest ~= "" do
    local key = rest:match("^<[^>]+>") or rest:sub(1, 1)
    rest = rest:sub(#key + 1)
    local text = #key == 1 or key == "<Space>"
    if not (text and mode:match("^i")) then table.insert(new, key) end
  end
  if #new == 0 then return end
  vim.schedule(function()
    for _, key in ipairs(new) do table.insert(keys, names[key] or key) end
    while #keys > 6 do table.remove(keys, 1) end
    render()
    timer:stop()
    timer:start(4000, 0, vim.schedule_wrap(hide))
  end)
end)
