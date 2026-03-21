-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- スペルチェック設定（英語は残して日本語は除外）
vim.opt.spelllang = "en,cjk"

-- マークダウンの記号を隠さない（```や**などを全て表示）
vim.opt.conceallevel = 0

-- 行頭・行末で左右矢印キーが前後の行に移動できるようにする
vim.opt.whichwrap:append("<,>,[,]")
