return {
	"balaenis/pi-x-ide",
	build = function(plugin)
		vim.opt.rtp:prepend(plugin.dir .. "/ide-plugins/nvim")
		require("pi_x_ide.download").run({ refresh = true })
	end,
	init = function(plugin)
		vim.opt.rtp:prepend(plugin.dir .. "/ide-plugins/nvim")
	end,
	main = "pi_x_ide",
	opts = {
		keymap = "<leader>ga",
	},
}
