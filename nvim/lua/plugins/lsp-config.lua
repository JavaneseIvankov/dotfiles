return {
	"neovim/nvim-lspconfig",
	keys = {
		-- { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "Go to definition" },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- Helper function for common LSP setups
		local function setup_server(server_name, config)
			config = config or {}
			config.capabilities = capabilities
			lspconfig[server_name].setup(config)
		end

		-- Python LSP
		setup_server("pyright", {
			root_dir = function(fname)
				return lspconfig.util.find_git_ancestor(fname) or vim.fn.getcwd()
			end,
			settings = {
				python = {
					analysis = {
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						diagnosticMode = "workspace",
						typeCheckingMode = "loose",
					},
				},
			},
		})

		-- TypeScript/JavaScript LSP
		-- setup_server("ts_ls")
		setup_server("vtsls")
		setup_server("emmet_language_server")

		setup_server("kotlin_language_server")

		setup_server("gopls")

		setup_server("lua_ls")

		setup_server("marksman")

		setup_server("hls")
		setup_server("haskell_language_server")
	end,
}
