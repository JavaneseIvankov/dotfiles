return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		local defaults = require("lsp.defaults")

		-- 1. Setup Mason to install servers
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls" }, -- Add other servers here
			automatic_enable = true, -- Default: auto-enables installed servers
		})

		-- 2. Configure servers natively with vim.lsp.config()

		-- Default configuration for all servers
		vim.lsp.config("*", {
			capabilities = defaults.capabilities,
			on_attach = defaults.on_attach,
		})

		-- Custom configuration for Lua
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { checkThirdParty = false },
					telemetry = { enable = false },
				},
			},
		})
	end,
}
