-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Spell check (keep English, exclude Japanese)
vim.opt.spelllang = "en,cjk"

-- Do not conceal Markdown syntax (show ``` , ** and the like)
vim.opt.conceallevel = 0

-- Let left/right arrow keys wrap to the previous/next line at line boundaries
vim.opt.whichwrap:append("<,>,[,]")
