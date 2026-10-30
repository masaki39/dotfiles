vim.g.markdown_recommended_style = 0

-- Options
local opt = vim.opt
opt.breakindent = true
opt.clipboard = "unnamedplus"
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.ignorecase = true
opt.linebreak = true
opt.number = true
opt.relativenumber = true
opt.scrolloff = 4
opt.shiftwidth = 2
opt.smartcase = true
opt.spelllang = "en,cjk" -- keep English, exclude Japanese
opt.undofile = true
opt.whichwrap:append("<,>,[,]") -- let arrow keys wrap at line boundaries

-- Keymaps
local map = vim.keymap.set

-- Disable right click (prevents the Inspect popup)
map({ "n", "v", "i" }, "<RightMouse>", "<Nop>")

-- Visual line movement (wrap-aware)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map("i", "<Up>", "<C-o>gk")
map("i", "<Down>", "<C-o>gj")

map({ "n", "i", "s" }, "<Esc>", "<cmd>nohlsearch<cr><Esc>")
map({ "n", "i", "x", "s" }, "<C-s>", "<cmd>write<cr><Esc>")

-- Autocmds
local autocmd = vim.api.nvim_create_autocmd

-- Reload files changed outside of nvim (e.g. by coding agents)
autocmd("FocusGained", { command = "silent! checktime" })

-- Restore the last cursor position (git message buffers always start at the top)
autocmd("BufWinEnter", {
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "gitcommit" or ft == "gitrebase" or vim.b[args.buf].last_loc_done then
      return
    end
    vim.b[args.buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd("FileType", {
  pattern = { "text", "markdown", "gitcommit" },
  command = "setlocal spell",
})

-- Theme
vim.pack.add({ "https://github.com/folke/tokyonight.nvim" }, { confirm = false })
require("tokyonight").setup({ style = "moon", transparent = true })
vim.cmd.colorscheme("tokyonight")
