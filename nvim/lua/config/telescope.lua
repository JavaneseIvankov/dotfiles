local fb_actions = require("telescope._extensions.file_browser.actions")

local telescope = require("telescope")
telescope.setup({
	extensions = {
		file_browser = {
			depth = 8,
			files = false,
			mappings = {
				["n"] = {
					["n"] = fb_actions.create,
					["r"] = fb_actions.rename,
					["m"] = fb_actions.move,
					["y"] = fb_actions.copy,
					["d"] = fb_actions.remove,
					["o"] = fb_actions.open,
					["-"] = fb_actions.goto_parent_dir,
					["_"] = fb_actions.goto_home_dir,
					["w"] = fb_actions.goto_cwd,
					["t"] = fb_actions.change_cwd,
					["f"] = fb_actions.toggle_browser,
					["h"] = fb_actions.toggle_hidden,
					["s"] = fb_actions.toggle_all,
				},
			},
		},
	},
})
