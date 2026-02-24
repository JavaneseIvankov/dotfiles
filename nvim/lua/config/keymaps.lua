local function map(mode, lhs, rhs)
	vim.keymap.set(mode, lhs, rhs, { silent = true })
end

map("n", "x", '"_x', { noremap })

map("n", "<S-j>", "", { noremap })
map("i", "jk", "<esc>", { noremap })

map("i", "<C-I>", "<C-O>:normal! ^i<CR>", { noremap = true })
map("i", "<C-A>", "<C-O>:normal! $<CR>", { noremap = true })

map("n", "<leader>ee", "<cmd> Oil --float <CR>", { noremap })

map("n", ";", ":", { noremap })

map("n", "<leader><leader>w", "<cmd> write <CR>")

local tel = require("telescope.builtin")
map("n", "<leader>fr", "<cmd> Telescope oldfiles <CR>", { noremap })
map("n", "<leader>ff", tel.find_files, {})
map("n", "<leader>fg", tel.live_grep, {})
map("n", "<leader>fb", tel.buffers, {})
map("n", "<leader>fh", tel.help_tags, {})
map("n", "<leader>fs", "<cmd> Telescope lsp_dynamic_workspace_symbols<CR>")
-- map("n", "<leader>fs", "<cmd> Telescope harpoon marks<CR>", { noremap })
map("n", "<leader>fd", "<cmd> Telescope diagnostics<CR>", { noremap })
map("n", "<leader>fe", "<cmd> Telescope file_browser<CR>", { noremap })

-- Window Navigation
-- map("n", "<C-h>", "<C-w>h")
-- map("n", "<C-l>", "<C-w>l")
-- map("n", "<C-k>", "<C-w>k")
-- map("n", "<C-j>", "<C-w>j")

-- Resize Windows
map("n", "<C-Left>", "<C-w><")
map("n", "<C-Right>", "<C-w>>")
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

-- Obsidian Nvim keybinds
vim.api.nvim_set_keymap("n", "<leader>ls", "<cmd>ObsidianQuickSwitch<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>lo", "<cmd>ObsidianOpen<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>ln", "<cmd>ObsidianNew<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>lf", "<cmd>ObsidianSearch<cr>", { noremap = true, silent = true })

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
