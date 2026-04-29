-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- 右クリックを無効化（Inspectポップアップを防ぐ）
map({ "n", "v", "i" }, "<RightMouse>", "<Nop>", {})

-- Insert mode: visual line movement (wrap-aware)
map("i", "<Up>", "<C-o>gk", { desc = "Move Up (visual)" })
map("i", "<Down>", "<C-o>gj", { desc = "Move Down (visual)" })
