local M = {}

local namespace = vim.api.nvim_create_namespace("tmux_review_ansi")

local ansi16 = {
  "#000000", "#800000", "#008000", "#808000",
  "#000080", "#800080", "#008080", "#c0c0c0",
  "#808080", "#ff0000", "#00ff00", "#ffff00",
  "#0000ff", "#ff00ff", "#00ffff", "#ffffff",
}

local function xterm_color(index)
  index = tonumber(index)
  if not index then return nil end
  index = math.max(0, math.min(index, 255))
  if index < 16 then return ansi16[index + 1] end

  if index < 232 then
    local levels = { 0, 95, 135, 175, 215, 255 }
    local n = index - 16
    return ("#%02x%02x%02x"):format(
      levels[math.floor(n / 36) + 1],
      levels[math.floor(n / 6) % 6 + 1],
      levels[n % 6 + 1]
    )
  end

  local gray = 8 + 10 * (index - 232)
  return ("#%02x%02x%02x"):format(gray, gray, gray)
end

local function split_keep_empty(value, separator)
  local result, start = {}, 1
  while true do
    local at = value:find(separator, start, true)
    if not at then
      result[#result + 1] = value:sub(start)
      return result
    end
    result[#result + 1] = value:sub(start, at - 1)
    start = at + #separator
  end
end

local function sgr_codes(params)
  local codes = {}
  for _, part in ipairs(split_keep_empty(params, ";")) do
    if part:find(":", 1, true) then
      local sub = split_keep_empty(part, ":")
      local code, mode = tonumber(sub[1]), tonumber(sub[2])
      if code == 38 or code == 48 then
        codes[#codes + 1] = code
        codes[#codes + 1] = mode
        if mode == 5 then
          codes[#codes + 1] = tonumber(sub[3]) or 0
        elseif mode == 2 then
          local color_start = sub[3] == "" and 4 or (#sub >= 6 and 4 or 3)
          for i = color_start, color_start + 2 do
            codes[#codes + 1] = tonumber(sub[i]) or 0
          end
        end
      else
        codes[#codes + 1] = code or 0
      end
    else
      codes[#codes + 1] = tonumber(part) or 0
    end
  end
  return codes
end

local function apply_sgr(style, params)
  local codes = sgr_codes(params)
  local i = 1
  while i <= #codes do
    local code = codes[i]
    if code == 0 then
      style.fg, style.bg = nil, nil
      style.bold, style.italic = false, false
      style.underline, style.reverse, style.strike = false, false, false
    elseif code == 1 then
      style.bold = true
    elseif code == 3 then
      style.italic = true
    elseif code == 4 then
      style.underline = true
    elseif code == 7 then
      style.reverse = true
    elseif code == 9 then
      style.strike = true
    elseif code == 22 then
      style.bold = false
    elseif code == 23 then
      style.italic = false
    elseif code == 24 then
      style.underline = false
    elseif code == 27 then
      style.reverse = false
    elseif code == 29 then
      style.strike = false
    elseif code >= 30 and code <= 37 then
      style.fg = ansi16[code - 29]
    elseif code >= 40 and code <= 47 then
      style.bg = ansi16[code - 39]
    elseif code >= 90 and code <= 97 then
      style.fg = ansi16[code - 81]
    elseif code >= 100 and code <= 107 then
      style.bg = ansi16[code - 91]
    elseif code == 39 then
      style.fg = nil
    elseif code == 49 then
      style.bg = nil
    elseif code == 38 or code == 48 then
      local field = code == 38 and "fg" or "bg"
      if codes[i + 1] == 5 then
        style[field] = xterm_color(codes[i + 2])
        i = i + 2
      elseif codes[i + 1] == 2 then
        local r = math.max(0, math.min(codes[i + 2] or 0, 255))
        local g = math.max(0, math.min(codes[i + 3] or 0, 255))
        local b = math.max(0, math.min(codes[i + 4] or 0, 255))
        style[field] = ("#%02x%02x%02x"):format(r, g, b)
        i = i + 4
      end
    end
    i = i + 1
  end
end

local function style_key(style)
  return table.concat({
    style.fg or "-", style.bg or "-",
    style.bold and "b" or "-", style.italic and "i" or "-",
    style.underline and "u" or "-", style.reverse and "r" or "-",
    style.strike and "s" or "-",
  }, ":")
end

local function has_style(style)
  return style.fg ~= nil or style.bg ~= nil or style.bold or style.italic
      or style.underline or style.reverse or style.strike
end

local function copy_style(style)
  return {
    fg = style.fg, bg = style.bg, bold = style.bold, italic = style.italic,
    underline = style.underline, reverse = style.reverse, strike = style.strike,
  }
end

local function parse_ansi(data)
  local lines, spans, line_parts = {}, {}, {}
  local style = {}
  local row, col, run, ended_with_newline = 0, 0, nil, false

  local function finish_run()
    if run and col > run.start then
      spans[#spans + 1] = {
        row = row, start_col = run.start, end_col = col, style = run.style,
      }
    end
    run = nil
  end

  local function add_text(text)
    local key = has_style(style) and style_key(style) or nil
    if key ~= (run and run.key) then
      finish_run()
      if key then run = { start = col, key = key, style = copy_style(style) } end
    end
    line_parts[#line_parts + 1] = text
    col = col + #text
    ended_with_newline = false
  end

  local i = 1
  while i <= #data do
    local byte = data:byte(i)
    if byte == 27 then
      local next_byte = data:byte(i + 1)
      if next_byte == 91 then
        local last = i + 2
        while last <= #data do
          local value = data:byte(last)
          if value >= 0x40 and value <= 0x7e then break end
          last = last + 1
        end
        if last <= #data then
          if data:sub(last, last) == "m" then
            finish_run()
            apply_sgr(style, data:sub(i + 2, last - 1))
          end
          i = last + 1
        else
          i = #data + 1
        end
      elseif next_byte == 93 then
        local last = i + 2
        while last <= #data do
          if data:byte(last) == 7 then
            last = last + 1
            break
          elseif data:byte(last) == 27 and data:sub(last + 1, last + 1) == "\\" then
            last = last + 2
            break
          end
          last = last + 1
        end
        i = last
      else
        i = math.min(i + 2, #data + 1)
      end
    elseif byte == 10 then
      finish_run()
      lines[#lines + 1] = table.concat(line_parts)
      line_parts = {}
      row, col = row + 1, 0
      ended_with_newline = true
      i = i + 1
    elseif byte < 32 and byte ~= 9 or byte == 127 then
      i = i + 1
    else
      local length = 1
      if byte >= 0xf0 then length = 4
      elseif byte >= 0xe0 then length = 3
      elseif byte >= 0xc0 then length = 2 end
      local text = data:sub(i, math.min(i + length - 1, #data))
      add_text(text)
      i = i + #text
    end
  end
  finish_run()
  lines[#lines + 1] = table.concat(line_parts)

  if ended_with_newline then lines[#lines] = nil end
  if #lines == 0 then lines = { "" } end

  local line_lengths = {}
  for index, line in ipairs(lines) do
    line = line:gsub("[ \t\r\v\f]+$", "")
    lines[index] = line
    line_lengths[index] = #line
  end

  local trimmed_spans = {}
  for _, span in ipairs(spans) do
    local length = line_lengths[span.row + 1]
    if length and span.start_col < length then
      span.end_col = math.min(span.end_col, length)
      if span.end_col > span.start_col then
        trimmed_spans[#trimmed_spans + 1] = span
      end
    end
  end

  return lines, trimmed_spans, ended_with_newline
end

function M.apply(buf, raw_path)
  buf = buf or vim.api.nvim_get_current_buf()
  local file = assert(io.open(raw_path, "rb"), "cannot read tmux ANSI capture")
  local raw = file:read("*a")
  file:close()

  local lines, spans, ended_with_newline = parse_ansi(raw)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].endofline = ended_with_newline
  vim.bo[buf].fileformat = "unix"

  local path = vim.api.nvim_buf_get_name(buf)
  if path ~= "" then
    local result
    if ended_with_newline then
      result = vim.fn.writefile(lines, path)
    else
      result = vim.fn.writefile(lines, path, "b")
    end
    if result ~= 0 then error("cannot write plain tmux review capture") end
  end
  vim.bo[buf].modified = false

  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  local groups, group_number = {}, 0
  for _, span in ipairs(spans) do
    local key = style_key(span.style)
    local group = groups[key]
    if not group then
      group_number = group_number + 1
      group = "TmuxReviewAnsi" .. group_number
      groups[key] = group
      local hl = {
        fg = span.style.fg, bg = span.style.bg, bold = span.style.bold,
        italic = span.style.italic, underline = span.style.underline,
        reverse = span.style.reverse, strikethrough = span.style.strike,
      }
      vim.api.nvim_set_hl(0, group, hl)
    end
    vim.api.nvim_buf_set_extmark(buf, namespace, span.row, span.start_col, {
      end_row = span.row,
      end_col = span.end_col,
      hl_group = group,
      priority = 200,
    })
  end
end

return M
