-- List editing in insert mode (outside code fences):
--   <CR> at the end of a list item continues the list; on an empty item it
--   dedents a nested item or ends a top-level list
--   <Tab> / <S-Tab> on a list item indents / dedents it
--   <Space> on an empty line (outside front matter) starts a "- " item
-- Changes are made by feeding keys so that undo and dot-repeat record them.

vim.opt_local.autoindent = true -- <CR> relies on it to keep the item's indent

local function parse(line)
  local indent, marker, rest = line:match("^(%s*)([-*+])%s+(.*)$")
  if marker then
    -- "* * *" and the like are thematic breaks, not list items
    if (marker .. " " .. rest):match("^[" .. marker .. "%s]+$") and #rest:gsub("%s", "") >= 2 then
      return
    end
    return indent, marker, rest
  end
  local num, delim
  indent, num, delim, rest = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
  if num and #num <= 9 then -- CommonMark allows at most 9 digits
    return indent, (tonumber(num) + 1) .. delim, rest
  end
end

-- Whether line `row` (1-based) is inside a fenced code block or front matter
local function in_code(row)
  local lines = vim.api.nvim_buf_get_lines(0, 0, row - 1, false)
  local fence -- opening fence ("```", "~~~~", ...) while inside a code block
  local start = 1
  if lines[1] == "---" then
    local closed = false
    for i = 2, #lines do
      if lines[i] == "---" or lines[i] == "..." then
        closed, start = true, i + 1
        break
      end
    end
    if not closed then
      return true
    end
  end
  for i = start, #lines do
    local run = lines[i]:match("^%s*(```+)") or lines[i]:match("^%s*(~~~+)")
    if run then
      if not fence then
        fence = run
      elseif run:sub(1, 1) == fence:sub(1, 1) and #run >= #fence
        and lines[i]:match("^%s*[`~]+%s*$") then
        fence = nil
      end
    end
  end
  return fence ~= nil
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "ni", false)
end

local function current_item()
  if vim.fn.pumvisible() == 1 then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if in_code(row) then
    return
  end
  return parse(vim.api.nvim_get_current_line())
end

local function list_cr()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local indent, marker, rest = current_item()
  if not marker or col < #line then
    return feed("<CR>")
  end

  local box = rest:match("^%[.%]%s*")
  if (box and rest:sub(#box + 1) or rest) == "" then
    return feed(indent == "" and "<C-u>" or "<C-d>")
  end
  feed("<CR>" .. marker .. " " .. (box and "[ ] " or ""))
end

local function on_list_item(keys, default)
  return function()
    feed(current_item() and keys or default)
  end
end

local map = vim.keymap.set
map("i", "<CR>", list_cr, { buffer = true })
map("i", "<Tab>", on_list_item("<C-t>", "<Tab>"), { buffer = true })
map("i", "<S-Tab>", on_list_item("<C-d>", "<S-Tab>"), { buffer = true })

-- InsertCharPre instead of a <Space> mapping: a mapping sees a stale line while
-- typed-ahead characters are still being inserted
local group = vim.api.nvim_create_augroup("markdown_list", { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = 0 })
vim.api.nvim_create_autocmd("InsertCharPre", {
  group = group,
  buffer = 0,
  callback = function()
    if vim.v.char == " " and vim.api.nvim_get_current_line() == ""
      and not in_code(vim.api.nvim_win_get_cursor(0)[1]) then
      vim.v.char = "- "
    end
  end,
})

local undo = "setlocal autoindent< | exe 'silent! iunmap <buffer> <CR>'"
  .. " | exe 'silent! iunmap <buffer> <Tab>' | exe 'silent! iunmap <buffer> <S-Tab>'"
  .. " | exe 'autocmd! markdown_list * <buffer>'"
local prev = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (prev and prev ~= "") and (prev .. " | " .. undo) or undo
