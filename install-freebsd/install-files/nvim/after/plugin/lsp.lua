config = require('arb.lsp-conf').mk_config()

local lsp = require('lsp-zero').preset({
  name = 'minimal',
  set_lsp_keymaps = true,
  manage_nvim_cmp = true,
  suggest_lsp_servers = false,
})

lsp.ensure_installed({
  'jdtls',
  'pylsp',
  'ruby-lsp',
  'sorbet'
})

lsp.skip_server_setup({'jdtls'})

lsp.on_attach(function(client, bufnr)
  require('arb.lsp-conf').on_attach(client, bufnr)
end)

-- (Optional) Configure lua language server for neovim
lsp.nvim_workspace()

lsp.setup()
