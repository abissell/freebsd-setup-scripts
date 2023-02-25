vim.g.mapleader=" "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move Visual blocks up and down with J/K
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor in same spot when appending lines with J
vim.keymap.set("n", "J", "mzJ`z")
