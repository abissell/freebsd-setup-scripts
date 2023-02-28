-- Some inspiration from https://github.com/mfussenegger/dotfiles/commit/072ac8533baad3db16499a65eb9a94d69095b04a
local jdtls = require('jdtls')
local config = require('arb.lsp-conf').mk_config()
local root_dir = vim.fs.dirname(vim.fs.find({'.gradlew', '.git', 'mvnw'}, { upward = true })[1])
config.root_dir = root_dir
config.settings = {
  java = {
    -- Many options explained here: https://www.npmjs.com/package/coc-java?activeTab=readme
    cleanup = {
      actionsOnSave = {
        'addOverride',
        'addDeprecated',
        'stringConcatToTextBlock',
        'invertEquals',
        'addFinalModifier',
        'instanceofPatternMatch',
        'lambdaExpression',
        'switchExpression',
      },
    },
    codeGeneration = {
      toString = {
        template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
      },
      hashCodeEquals = {
        useJava7Objects = true,
      },
      useBlocks = true,
    },
    completion = {
      favoriteStaticMembers = {
        "org.hamcrest.MatcherAssert.assertThat",
        "org.hamcrest.Matchers.*",
        "org.hamcrest.CoreMatchers.*",
        "org.junit.jupiter.api.Assertions.*",
        "java.util.Objects.requireNonNull",
        "java.util.Objects.requireNonNullElse",
        "org.mockito.Mockito.*"
      },
      filteredTypes = {
        "com.sun.*",
        "io.micrometer.shaded.*",
        "java.awt.*",
        "jdk.*", "sun.*",
      },
    },
    -- If you are developing in projects with different Java versions, you need
    -- to tell eclipse.jdt.ls to use the location of the JDK for your Java version
    -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    -- And search for `interface RuntimeOption`
    -- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
    configuration = {
      runtimes = {
        {
          name = "JavaSE-19",
          path = "/usr/local/openjdk19"
        },
        {
          name = "JavaSE-17",
          path = "/usr/local/openjdk17"
        },
        {
          name = "JavaSE-1.8",
          path = "/usr/local/openjdk8"
        },
      }
    },
    contentProvider = { preferred = 'fernflower' },  -- Use fernflower to decompile library code
    format = {
      settings = {
        -- Use Google Java style guidelines for formatting (with 4 spaces instead of 2)
        -- To use, make sure to download the file from https://github.com/google/styleguide/blob/gh-pages/eclipse-java-google-style.xml
        -- and place it in the ~/.local/share/eclipse directory
        url = "/.local/share/eclipse/eclipse-java-google-style-4-spaces.xml",
        profile = "GoogleStyle4Spaces",
      },
    },
    implementationsCodeLens = { enabled = true },
    inlayHints = {
      parameterNames = {
        enabled = true
      },
    },
    maven = {
      downloadSources = true,
      updateSnapshots = true,
    },
    quickfix = { showAt = "line" },
    referenceCodeLens = { enabled = true },
    saveActions = { organizeImports = true },
    signatureHelp = { enabled = true },
    sources = {
      organizeImports = {
        starThreshold = 9999;
        staticStarThreshold = 9999;
      },
    },
  },
}
local jdtls_jar = vim.fn.glob(vim.fn.stdpath('data') .. '/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar')
local jdtls_conf = vim.fn.stdpath('data') .. '/mason/packages/jdtls/config_linux'
local home = os.getenv('HOME')
local workspace_folder = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")
config.cmd = {
  '/usr/local/openjdk19/bin/java',
  '-Declipse.application=org.eclipse.jdt.ls.core.id1',
  '-Dosgi.bundles.defaultStartLevel=4',
  '-Declipse.product=org.eclipse.jdt.ls.core.product',
  '-Dlog.protocol=true',
  '-Dlog.level=ALL',
  '-Xms1g',
  '-Xmx2g',
  '--enable-preview',
  '--add-modules=ALL-SYSTEM',
  '--add-opens', 'java.base/java.util=ALL-UNNAMED',
  '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
  '-jar', jdtls_jar,
  '-configuration', jdtls_conf,
  '-data', workspace_folder,
}
-- Helper function for creating keymaps
local function nnoremap(rhs, lhs, bufopts, desc)
  bufopts.desc = desc
  vim.keymap.set('n', rhs, lhs, bufopts)
end
config.on_attach = function(client, bufnr)
  -- Load the generic LSP on_attach
  require('arb.lsp-conf').on_attach(client, bufnr, {
    server_side_fuzzy_completion = true,
  })
  -- These defaults are set by `set_lsp_keymaps = true` in the vanilla lsp-zero config
  -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v1.x/doc/md/lsp.md#default-keybindings
  -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/64c065a455f9e0d4e7d0ab263ae01be2855b4590/lua/lsp-zero/server.lua#L242
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  nnoremap('K', vim.lsp.buf.hover, bufopts, "Hover text")
  nnoremap('gd', vim.lsp.buf.definition, bufopts, "Go to definition")
  nnoremap('gD', vim.lsp.buf.declaration, bufopts, "Go to declaration")
  nnoremap('gi', vim.lsp.buf.implementation, bufopts, "Go to implementation")
  nnoremap('go', vim.lsp.buf.type_definition, bufopts, "Go to type definition")
  nnoremap('gr', vim.lsp.buf.references, bufopts, "List all references to symbol under cursor")
  nnoremap('<C-k>', vim.lsp.buf.signature_help, bufopts, "Show signature")
  nnoremap('<F2>', vim.lsp.buf.rename, bufopts, "Rename all references to symbol under cursor")
  nnoremap('<F4>', vim.lsp.buf.code_action, bufopts, "Code actions")
  local range_ca_bufopts = { noremap=true, silent=true, buffer=bufnr, desc="Range code actions" }
  vim.keymap.set('x', '<F4>', vim.lsp.buf.range_code_action, range_ca_bufopts)
  nnoremap('gl', vim.diagnostic.open_float, bufopts, "Show diagnostics in floating window")
  nnoremap('[d', vim.diagnostic.goto_prev, bufopts, "Move to previous diagnotic in current buffer")
  nnoremap(']d', vim.diagnostic.goto_next, bufopts, "Move to next diagnotic in current buffer")

  -- Java extensions provided by jdtls
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  nnoremap("<C-o>", jdtls.organize_imports, bufopts, "Organize imports")
  nnoremap("<space>ev", jdtls.extract_variable, bufopts, "Extract variable")
  nnoremap("<space>ec", jdtls.extract_constant, bufopts, "Extract constant")
  vim.keymap.set('v', "<space>em", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
    { noremap=true, silent=true, buffer=bufnr, desc = "Extract method" })
end
jdtls.start_or_attach(config)
