return {
	"nvimdev/dashboard-nvim",
	enabled = true,
	event = "VimEnter",
	config = function()
		require("dashboard").setup({
			theme = "doom",
			config = {
				header = {
					"⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⢠⡆⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⠀⠈⣷⣄⠀⠀⠀⠀⣾⣷⠀⠀⠀⠀⣠⣾⠃⠀⠀⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⠀⠀⢿⠿⠃⠀⠀⠀⠉⠉⠁⠀⠀⠐⠿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣤⣤⣶⣶⣶⣤⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣄⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⣠⣶⣿⣿⡿⣿⣿⣿⡿⠋⠉⠀⠀⠉⠙⢿⣿⣿⡿⣿⣿⣷⣦⡀⠀⠀⠀",
					"⠀⢀⣼⣿⣿⠟⠁⢠⣿⣿⠏⠀⠀⢠⣤⣤⡀⠀⠀⢻⣿⣿⡀⠙⢿⣿⣿⣦⠀⠀",
					"⣰⣿⣿⡟⠁⠀⠀⢸⣿⣿⠀⠀⠀⢿⣿⣿⡟⠀⠀⠈⣿⣿⡇⠀⠀⠙⣿⣿⣷⡄",
					"⠈⠻⣿⣿⣦⣄⠀⠸⣿⣿⣆⠀⠀⠀⠉⠉⠀⠀⠀⣸⣿⣿⠃⢀⣤⣾⣿⣿⠟⠁",
					"⠀⠀⠈⠻⣿⣿⣿⣶⣿⣿⣿⣦⣄⠀⠀⠀⢀⣠⣾⣿⣿⣿⣾⣿⣿⡿⠋⠁⠀⠀",
					"⠀⠀⠀⠀⠀⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠁⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠛⠿⠿⠿⠿⠿⠿⠿⠿⠛⠋⠁⠀⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⠀⠀⢰⣷⡦⠀⠀⠀⢀⣀⣀⠀⠀⠀⢴⣾⡇⠀⠀⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⠀⠀⣸⠟⠁⠀⠀⠀⠘⣿⡇⠀⠀⠀⠀⠙⢷⠀⠀⠀⠀⠀⠀⠀⠀",
					"⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠻⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀",
					"                              ",
					"                              ",
					"                              ",
					"                              ",
					"                              ",
				}, -- your header
				center = {
					{
						icon = " ",
						icon_hl = "Title",
						desc = "Find Recent File           ",
						desc_hl = "String",
						key = "r",
						-- keymap = "SPC f r",
						key_hl = "Number",
						key_format = " %s", -- remove default surrounding `[]`
						action = "Telescope oldfiles",
					},
					{
						icon = " ",
						desc = "Obsidian Dashboard",
						key = "o",
						-- keymap = "o",
						key_format = " %s", -- remove default surrounding `[]`
						action = "e ~/Documents/Workspace/General_Vault/0000_Dashboard.md",
					},
				},
				footer = { "::---::" }, -- your footer
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
