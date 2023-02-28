-- reserve space for diagnostic icons
vim.opt.signcolumn = 'yes'

local M = {}

-- Helper function for creating keymaps
local function nnoremap(rhs, lhs, bufopts, desc)
  bufopts.desc = desc
  vim.keymap.set('n', rhs, lhs, bufopts)
end

-- The on_attach function is used to set key maps after the language server
-- attaches to the current buffer
local on_attach = function(client, bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }

  -- These defaults are set by `set_lsp_keymaps = true` in the vanilla lsp-zero config
  -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v1.x/doc/md/lsp.md#default-keybindings
  -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/64c065a455f9e0d4e7d0ab263ae01be2855b4590/lua/lsp-zero/server.lua#L242
  -- nnoremap('K', vim.lsp.buf.hover, bufopts, "Hover text")
  -- nnoremap('gd', vim.lsp.buf.definition, bufopts, "Go to definition")
  -- nnoremap('gD', vim.lsp.buf.declaration, bufopts, "Go to declaration")
  -- nnoremap('gi', vim.lsp.buf.implementation, bufopts, "Go to implementation")
  -- nnoremap('go', vim.lsp.buf.type_definition, bufopts, "Go to type definition")
  -- nnoremap('gr', vim.lsp.buf.references, bufopts, "List all references to symbol under cursor")
  -- nnoremap('<C-k>', vim.lsp.buf.signature_help, bufopts, "Show signature")
  -- nnoremap('<F2>', vim.lsp.buf.rename, bufopts, "Rename all references to symbol under cursor")
  -- nnoremap('<F4>', vim.lsp.buf.code_action, bufopts, "Code actions")
  -- local range_ca_bufopts = { noremap=true, silent=true, buffer=bufnr, desc="Range code actions" }
  -- vim.keymap.set('x', '<F4>', vim.lsp.buf.range_code_action, range_ca_bufopts)
  -- nnoremap('gl', vim.diagnostic.open_float, bufopts, "Show diagnostics in floating window")
  -- nnoremap('[d', vim.diagnostic.goto_prev, bufopts, "Move to previous diagnotic in current buffer")
  -- nnoremap(']d', vim.diagnostic.goto_next, bufopts, "Move to next diagnotic in current buffer")

  nnoremap('<space>f', function() vim.lsp.buf.format { async = true } end, bufopts, "Format file")
end
M.on_attach = on_attach

local function mk_config()
  return {
    flags = {
      debounce_text_changes = 150,
      allow_incremental_sync = true,
    },
    on_attach = on_attach,
  }
end
M.mk_config = mk_config

return M
