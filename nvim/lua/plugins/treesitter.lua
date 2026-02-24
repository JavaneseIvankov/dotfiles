return {
	{
		"nvim-treesitter/nvim-treesitter",
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
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup()
		end,
	},
}
