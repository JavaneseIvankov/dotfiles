return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	build = ":TSUpdate",
	opts = {
		ensure_installed = {
			"bash",
			"css",
			"gitignore",
			"html",
			"javascript",
			"java",
			"json",
			"lua",
			"markdown",
			"markdown_inline",
			"php",
			"python",
			"query",
			"regex",
			"scss",
			"sql",
			"tsx",
			"typescript",
			"vim",
			"vue",
			"yaml",
			"kotlin",
			"haskell",
			"go", -- Changed "gopls" to "go"
		},
		highlight = { enable = true },
		indent = { enable = true },
	},
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)
	end,
}
