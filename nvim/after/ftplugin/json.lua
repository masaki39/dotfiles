-- A file that is a single long line (minified) is pretty-printed with jq when opened.
-- The buffer is left untouched when jq fails (invalid JSON, comments, ...).

local buf = vim.api.nvim_get_current_buf()
if vim.b[buf].json_expanded or vim.fn.executable("jq") == 0
  or vim.api.nvim_buf_line_count(buf) ~= 1 or #vim.api.nvim_get_current_line() <= 120 then
  return
end
vim.b[buf].json_expanded = true

local res = vim.system({ "jq", "--indent", tostring(vim.fn.shiftwidth()), "." },
  { stdin = vim.api.nvim_get_current_line() }):wait()
if res.code ~= 0 then
  return
end
local out = vim.split(res.stdout:gsub("\n$", ""), "\n")
if #out > 1 then
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].modified = false -- only viewing shouldn't prompt; any save writes it expanded
end
