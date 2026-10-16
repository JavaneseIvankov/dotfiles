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

-- Copy buffer path to clipboard
local function get_active_buffer_path(relative)
	local path = vim.api.nvim_buf_get_name(0)

	if vim.bo.filetype == "oil" then
		local ok, oil = pcall(require, "oil")
		if ok then
			local dir = oil.get_current_dir(0)
			local entry = oil.get_cursor_entry()
			if dir and entry and entry.name then
				path = dir .. entry.name
			elseif dir then
				path = dir
			end
		end
	end

	if path:match("^oil://") then
		path = path:gsub("^oil://", "")
	end

	if path == "" then
		vim.notify("Current buffer has no file path", vim.log.levels.WARN)
		return nil
	end

	if relative then
		path = vim.fn.fnamemodify(path, ":.")
		if path == "" then
			path = "."
		end
	end

	return path
end

local function copy_buf_path(relative)
	local path = get_active_buffer_path(relative)
	if not path then
		return
	end
	vim.fn.setreg("+", path)
	vim.fn.setreg('"', path)
	local label = relative and "relative path" or "full path"
	vim.notify('Copied ' .. label .. ' to clipboard: "' .. path .. '"', vim.log.levels.INFO)
end

local function copy_buf_root_path()
	local path = get_active_buffer_path(false)
	if not path then
		return
	end

	local root = vim.fs.root(path, { ".git" })
		or vim.fs.root(path, { "package.json", "Cargo.toml", "go.mod", "pyproject.toml" })
		or vim.fn.getcwd()

	local rel = (root and vim.fs.relpath(root, path)) or vim.fn.fnamemodify(path, ":.")
	if rel == "" then
		rel = "."
	end

	vim.fn.setreg("+", rel)
	vim.fn.setreg('"', rel)
	vim.notify('Copied root-relative path to clipboard: "' .. rel .. '"', vim.log.levels.INFO)
end

local function copy_buf_name()
	local path = get_active_buffer_path(false)
	if not path then
		return
	end
	local filename = vim.fn.fnamemodify(path:gsub("/+$", ""), ":t")
	if filename == "" then
		filename = path
	end
	vim.fn.setreg("+", filename)
	vim.fn.setreg('"', filename)
	vim.notify('Copied file name to clipboard: "' .. filename .. '"', vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>cp", function()
	copy_buf_path(true)
end, { desc = "Copy relative buffer path to clipboard" })

vim.keymap.set("n", "<leader>cP", function()
	copy_buf_path(false)
end, { desc = "Copy full buffer path to clipboard" })

vim.keymap.set("n", "<leader>cr", copy_buf_root_path, { desc = "Copy root-relative path to clipboard" })

vim.keymap.set("n", "<leader>bp", function()
	copy_buf_path(true)
end, { desc = "Copy relative buffer path to clipboard" })

vim.keymap.set("n", "<leader>bP", function()
	copy_buf_path(false)
end, { desc = "Copy full buffer path to clipboard" })

vim.keymap.set("n", "<leader>br", copy_buf_root_path, { desc = "Copy root-relative path to clipboard" })

vim.keymap.set("n", "<leader>cf", copy_buf_name, { desc = "Copy buffer file name to clipboard" })

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
