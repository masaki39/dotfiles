-- A file that is a single long line (minified) is pretty-printed when opened.
-- Only whitespace is added: keys, escapes and numbers stay exactly as written.
-- Invalid JSON, huge files and buffers that can't be changed are left untouched.

local buf = vim.api.nvim_get_current_buf()
if not vim.bo[buf].modifiable or vim.api.nvim_buf_line_count(buf) ~= 1 then
  return
end
local src = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
if #src <= 120 or #src > 10 * 1024 * 1024 or not pcall(vim.json.decode, src) then
  return
end

local unit = vim.bo[buf].expandtab and string.rep(" ", vim.fn.shiftwidth()) or "\t"
local out, depth, i = {}, 0, 1
local function newline()
  out[#out + 1] = "\n" .. unit:rep(depth)
end
while i <= #src do
  local c = src:sub(i, i)
  if c == '"' then
    local j = i + 1
    while true do -- find the closing quote, skipping escaped characters
      j = src:find('["\\]', j)
      if src:sub(j, j) == '"' then
        break
      end
      j = j + 2
    end
    out[#out + 1] = src:sub(i, j)
    i = j + 1
  elseif c == "{" or c == "[" then
    local k = src:find("%S", i + 1)
    if src:sub(k, k) == (c == "{" and "}" or "]") then -- keep {} and [] together
      out[#out + 1] = c .. src:sub(k, k)
      i = k + 1
    else
      depth = depth + 1
      out[#out + 1] = c
      newline()
      i = i + 1
    end
  elseif c == "}" or c == "]" then
    depth = depth - 1
    newline()
    out[#out + 1] = c
    i = i + 1
  elseif c == "," then
    out[#out + 1] = c
    newline()
    i = i + 1
  elseif c == ":" then
    out[#out + 1] = ": "
    i = i + 1
  elseif c:match("%s") then
    i = i + 1
  else -- number, true, false, null
    local k = src:find('[%s,:%[%]{}"]', i) or #src + 1
    out[#out + 1] = src:sub(i, k - 1)
    i = k
  end
end

local lines = vim.split(table.concat(out), "\n")
if #lines > 1 then
  local was_modified = vim.bo[buf].modified
  local undolevels = vim.bo[buf].undolevels
  vim.bo[buf].undolevels = -1 -- not undoable: `u` shouldn't collapse it back
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].undolevels = undolevels
  vim.bo[buf].modified = was_modified -- just viewing shouldn't prompt; a save writes it expanded
end
