return {
	"tzachar/local-highlight.nvim",
	opts = {
		disable_file_types = { "tex" },
		hlgroup = "LocalHighlight",
		cw_hlgroup = nil,
		insert_mode = true,
		min_match_len = 1,
		max_match_len = math.huge,
		highlight_single_match = true,
		animate = {
			enabled = true,
			easing = "linear",
			duration = {
				step = 10, -- ms per step
				total = 100, -- maximum duration
			},
		},
		debounce_timeout = 200,
	},
}
