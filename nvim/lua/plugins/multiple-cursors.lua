return {
	"brenton-leighton/multiple-cursors.nvim",
	version = "*",
	opts = {
		pre_hook = function()
			vim.g.multiple_cursors_active = true
		end,
		post_hook = function()
			vim.g.multiple_cursors_active = false
		end,
	},
	init = function()
		vim.keymap.set("n", "n", function()
			if vim.g.multiple_cursors_active then
				return "<Cmd>MultipleCursorsJumpNextMatch<CR>"
			else
				return "n"
			end
		end, { expr = true, desc = "Jump to next cword" })

		vim.keymap.set("n", "N", function()
			if vim.g.multiple_cursors_active then
				return "<Cmd>MultipleCursorsJumpPrevMatch<CR>"
			else
				return "N"
			end
		end, { expr = true, desc = "Jump to next cword" })
	end,
	keys = {
		{ "<C-j>", "<Cmd>MultipleCursorsAddDown<CR>", mode = { "x" }, desc = "Add cursor and move down" },
		{ "<C-k>", "<Cmd>MultipleCursorsAddUp<CR>", mode = { "x" }, desc = "Add cursor and move up" },

		{ "<C-Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = { "n", "i", "x" }, desc = "Add cursor and move up" },
		{ "<C-Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = { "n", "i", "x" }, desc = "Add cursor and move down" },

		{
			"<C-LeftMouse>",
			"<Cmd>MultipleCursorsMouseAddDelete<CR>",
			mode = { "n", "i" },
			desc = "Add or remove cursor on mouse click",
		},
		{
			"<C-Return>",
			"<Cmd>MultipleCursorsAddDelete<CR>",
			mode = { "n" },
			desc = "Add a locked cursor or remove an existing cursor",
		},

		{
			"<Leader>m",
			"<Cmd>MultipleCursorsAddVisualArea<CR>",
			mode = { "x" },
			desc = "Add cursors to the lines of the visual area",
		},

		{ "<Leader>a", "<Cmd>MultipleCursorsAddMatches<CR>", mode = { "n", "x" }, desc = "Add cursors to cword" },
		{
			"<Leader>A",
			"<Cmd>MultipleCursorsAddMatchesV<CR>",
			mode = { "n", "x" },
			desc = "Add cursors to cword in previous area",
		},
		{
			"n",
			"<Cmd>MultipleCursorsAddJumpNextMatch<CR>",
			mode = { "x" },
			desc = "Add cursor and jump to next cword",
		},
		{
			"N",
			"<Cmd>MultipleCursorsAddJumpPrevMatch<CR>",
			mode = { "x" },
			desc = "Add cursor and jump to next cword",
		},

		{ "<Leader>l", "<Cmd>MultipleCursorsLock<CR>", mode = { "n", "x" }, desc = "Lock virtual cursors" },
	},
}
