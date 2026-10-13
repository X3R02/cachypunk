-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Leave terminal insert mode without the <C-\><C-n> gymnastics.
vim.keymap.set("t", "<A-q>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
