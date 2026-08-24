local function map(mode, lhs, rhs)
	vim.keymap.set(mode, lhs, rhs, { silent = true })
end

map("n", "x", '"_x', { noremap })

map("n", "<S-j>", "", { noremap })
map("i", "jk", "<esc>", { noremap })

map("i", "<C-p>", ":", { noremap })
map("n", "<C-p>", ":", { noremap })

map("i", "<C-I>", "<C-O>:normal! ^i<CR>", { noremap = true })
map("i", "<C-A>", "<C-O>:normal! $<CR>", { noremap = true })

map("n", "<leader>ee", "<cmd> Oil --float <CR>", { noremap })

map("n", ":", "q:i", { noremap })
map("n", ";", "q:i", { noremap })

map("n", "<leader><leader>w", "<cmd> write <CR>")

local tel = require("telescope.builtin")
map("n", "<leader>fr", "<cmd> Telescope oldfiles <CR>", { noremap })
map("n", "<leader>ff", tel.find_files, {})
map("n", "<leader>fg", tel.live_grep, {})
map("n", "<leader>fb", tel.buffers, {})
map("n", "<leader>fh", tel.help_tags, {})
map("n", "<leader>fs", "<cmd> Telescope lsp_dynamic_workspace_symbols<CR>")
map("n", "<leader>fd", "<cmd> Telescope diagnostics<CR>", { noremap })
map("n", "<leader>fe", "<cmd> Telescope file_browser<CR>", { noremap })

-- Window Navigation
-- map("n", "<C-h>", "<C-w>h")
-- map("n", "<C-l>", "<C-w>l")
-- map("n", "<C-k>", "<C-w>k")
-- map("n", "<C-j>", "<C-w>j")

-- Resize Windows
map("n", "<C-Left>", "<C-w>>")
map("n", "<C-Right>", "<C-w><")
map("n", "<C-Up>", "<C-w>+")
map("n", "<C-Down>", "<C-w>-")

-- Split Windows
map("n", "<leader>sh", "<cmd> split <CR>", { noremap })
map("n", "<leader>sv", "<cmd> vsplit <CR>", { noremap })

-- Kill Buffer
map("n", "<leader>q", "<cmd> q <CR>", { noremap })

-- Save Buffer
map("n", "<leader>bs", "<cmd> w <CR>", { noremap })
map("i", "<C>s", "<cmd> w <CR>", { noremap })

-- Navigate prev and next buff
map("n", "<leader>n", "<cmd> bnext<CR>", { noremap })
map("n", "<leader>p", "<cmd> bprev<CR>", { noremap })

-- Latex keybinds
vim.api.nvim_set_keymap("n", "<leader>gl", "<cmd>AsyncRun latexmk -pvc -pdf %<cr>", { noremap = true, silent = true })

-- hop keybinds
local hop = require("hop")
local directions = require("hop.hint").HintDirection
vim.keymap.set("", "f", function()
	hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
end, { remap = true })
vim.keymap.set("", "F", function()
	hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
end, { remap = true })
vim.keymap.set("", "t", function()
	hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
end, { remap = true })
vim.keymap.set("", "T", function()
	hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
end, { remap = true })

-- lsp keybinds
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap })
map("n", "H", vim.lsp.buf.hover, { noremap })

-- glance keybinds
map("n", "gD", "<CMD>Glance definitions<CR>")
map("n", "gR", "<CMD>Glance references<CR>")
map("n", "gY", "<CMD>Glance type_definitions<CR>")
map("n", "gM", "<CMD>Glance implementations<CR>")

-- bufferline keybinds
map("n", "<S-j>", ":bprevious<CR>", { silent = true, desc = "Prev buffer" })
map("n", "<S-k>", ":bnext<CR>", { silent = true, desc = "Next buffer" })

local function close_buffer_or_quit()
	local has_glance, glance = pcall(require, "glance")
	if has_glance and glance.is_open() then
		local winhl = vim.wo.winhighlight
		if vim.bo.filetype == "Glance" or (winhl and winhl:find("Glance")) then
			glance.actions.close()
			return
		end
	end
	--
	local buffers = vim.fn.getbufinfo({ buflisted = 1 })
	local buftype = vim.bo.buftype

	if buftype == "" and #buffers > 1 then
		vim.cmd("bdelete")
	elseif #buffers == 1 and buftype ~= "acwrite" then
		print("Press [ENTER] to exit...")
		local char = vim.fn.getchar()
		if char == 13 then
			vim.cmd("q")
		else
			vim.cmd("redraw")
		end
	else
		vim.cmd("q")
	end
end

-- Bind this to <leader>q in Normal mode
vim.keymap.set("n", "<leader>q", close_buffer_or_quit, { noremap = true, silent = true })

-- Aerial keybinds
vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")

-- Trouble keybinds
map("i", "<C-Shift>m", "<cmd>Trouble diagnostics<CR>")

-- zen
map("n", "<leader>zz", "<cmd>ZenMode<CR>")
