-- List editing in insert mode:
--   <CR> at the end of a list item continues the list (an empty item ends it)
--   <Tab> / <S-Tab> on a list item indents / dedents it
--   <Space> on an empty line (outside code fences) starts a "- " item

local function parse(line)
  local indent, marker, rest = line:match("^(%s*)([-*+])%s+(.*)$")
  if marker then
    return indent, marker, rest
  end
  local num, delim
  indent, num, delim, rest = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
  if num then
    return indent, (tonumber(num) + 1) .. delim, rest
  end
end

local function list_cr()
  local line = vim.api.nvim_get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local indent, marker, rest = parse(line)
  if vim.fn.pumvisible() == 1 or col < #line or not marker then
    vim.api.nvim_feedkeys(vim.keycode("<CR>"), "ni", false)
    return
  end

  local box = rest:match("^%[.%]%s*")
  if (box and rest:sub(#box + 1) or rest) == "" then
    vim.api.nvim_set_current_line("")
    return
  end

  local prefix = indent .. marker .. " " .. (box and "[ ] " or "")
  vim.api.nvim_buf_set_lines(0, row, row, false, { prefix })
  vim.api.nvim_win_set_cursor(0, { row + 1, #prefix })
end

local function in_code_fence(row)
  local inside = false
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, row - 1, false)) do
    if l:match("^%s*```") or l:match("^%s*~~~") then
      inside = not inside
    end
  end
  return inside
end

local function on_list_item(keys, default)
  return function()
    if vim.fn.pumvisible() == 0 and parse(vim.api.nvim_get_current_line()) then
      return keys
    end
    return default
  end
end

local map = vim.keymap.set
map("i", "<CR>", list_cr, { buffer = true })
map("i", "<Tab>", on_list_item("<C-t>", "<Tab>"), { buffer = true, expr = true })
map("i", "<S-Tab>", on_list_item("<C-d>", "<S-Tab>"), { buffer = true, expr = true })

-- InsertCharPre instead of a <Space> mapping: a mapping sees a stale line while
-- typed-ahead characters are still being inserted
local group = vim.api.nvim_create_augroup("markdown_list", { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = 0 })
vim.api.nvim_create_autocmd("InsertCharPre", {
  group = group,
  buffer = 0,
  callback = function()
    if vim.v.char == " " and vim.api.nvim_get_current_line() == ""
      and not in_code_fence(vim.api.nvim_win_get_cursor(0)[1]) then
      vim.v.char = "- "
    end
  end,
})

local undo = "exe 'silent! iunmap <buffer> <CR>' | exe 'silent! iunmap <buffer> <Tab>'"
  .. " | exe 'silent! iunmap <buffer> <S-Tab>' | exe 'autocmd! markdown_list * <buffer>'"
vim.b.undo_ftplugin = vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | " .. undo) or undo
