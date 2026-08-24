return {
  "neovim/nvim-lspconfig",
  config = function()
    -- 1. Definisikan Capabilities (untuk autocompletion)
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- 2. Fungsi pembantu untuk setup Native LSP
    local function enable_server(server_name, opts)
      opts = opts or {}
      -- Gabungkan capabilities bawaan dengan custom opts
      opts.capabilities = vim.tbl_deep_extend("force", capabilities, opts.capabilities or {})
      
      -- Daftarkan konfigurasi ke Neovim
      vim.lsp.config(server_name, opts)
      -- Aktifkan server (ini otomatis memasang autocommands untuk FileType terkait)
      vim.lsp.enable(server_name)
    end

    -- 3. Setup Python (Pyright) dengan konfigurasi khusus
    enable_server("pyright", {
      -- Migrasi root_dir ke vim.fs (Native) menggantikan lspconfig.util
      root_dir = function(fname)
        return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1]) or vim.fn.getcwd()
      end,
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,      -- Diubah ke camelCase
            useLibraryCodeForTypes = true,
            diagnosticMode = "workspace",
            typeCheckingMode = "loose",
          },
        },
      },
    })

    enable_server("gopls", {
      cmd = { "/home/arundaya/go/bin/gopls" },
    })

    -- 4. Setup Server Standar
    local servers = {
      "vtsls",
      "emmet_language_server",
      "lua_ls",
      "marksman",
      "bashls", -- Perbaikan nama: 'bash-language-server' -> 'bashls'
    }

    for _, server in ipairs(servers) do
      enable_server(server)
    end
  end,
}
