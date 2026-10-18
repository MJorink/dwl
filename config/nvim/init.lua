-- Plugins are managed by vim.pack (Neovim 0.12+); versions are pinned in
-- nvim-pack-lock.json next to this file. Update with :lua vim.pack.update()

-- Core ------------------------------------------------------------------------

vim.g.mapleader = " "
vim.g.mkdp_browser = "librewolf"
vim.g.mkdp_command_for_global = 1 -- alwaysAllowPreview
vim.g.nvim_surround_no_mappings = true -- custom gz binds below; must be set before the plugin loads

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "nvi"
vim.o.signcolumn = "yes"
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.timeoutlen = 500
vim.o.termguicolors = true

vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.scrolloff = 8
vim.o.updatetime = 50
vim.o.wrap = false
vim.o.guicursor = "n-v-i-c:block-Cursor"
vim.o.ignorecase = true -- searchCase = "smart"
vim.o.smartcase = true
vim.o.clipboard = "unnamedplus"
vim.o.undofile = true

-- XAML is XML; reuse the xml treesitter grammar
vim.filetype.add({ extension = { xaml = "xml", axaml = "xml" } })

-- Plugins ---------------------------------------------------------------------

-- Build steps after a plugin is installed or updated
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if kind ~= "install" and kind ~= "update" then
			return
		end
		if name == "markdown-preview.nvim" and vim.fn.executable("npm") == 1 then
			vim.system({ "npm", "install" }, { cwd = ev.data.path .. "/app" }):wait()
		elseif name == "nvim-treesitter" and kind == "update" then
			vim.cmd.packadd("nvim-treesitter")
			vim.cmd("TSUpdate")
		end
	end,
})

local gh = function(repo) return "https://github.com/" .. repo end
vim.pack.add({
	gh("ellisonleao/gruvbox.nvim"),
	gh("nvim-lualine/lualine.nvim"),
	gh("nvim-tree/nvim-web-devicons"),
	gh("lukas-reineke/indent-blankline.nvim"),
	{ src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
	gh("nvim-treesitter/nvim-treesitter-context"),
	gh("windwp/nvim-autopairs"),
	gh("numToStr/Comment.nvim"),
	gh("kylechui/nvim-surround"),
	gh("nvim-lua/plenary.nvim"),
	gh("nvim-telescope/telescope.nvim"),
	gh("mbbill/undotree"),
	gh("folke/which-key.nvim"),
	gh("neovim/nvim-lspconfig"),
	gh("stevearc/conform.nvim"),
	gh("folke/trouble.nvim"),
	gh("akinsho/toggleterm.nvim"),
	gh("iamcco/markdown-preview.nvim"),
	gh("MeanderingProgrammer/render-markdown.nvim"),
}, { confirm = false })

-- UI --------------------------------------------------------------------------

vim.o.background = "dark"
require("gruvbox").setup({})
vim.cmd.colorscheme("gruvbox")

require("lualine").setup({ options = { theme = "auto", globalstatus = true } })
require("ibl").setup()
require("which-key").setup({ preset = "modern" })
require("which-key").add({
	{ "<leader>f", group = "Telescope" },
	{ "<leader>fl", group = "LSP" },
	{ "<leader>fv", group = "Git" },
	{ "<leader>l", group = "LSP" },
	{ "<leader>x", group = "Trouble" },
})

-- Treesitter ------------------------------------------------------------------

-- Parsers are compiled locally by nvim-treesitter (needs tree-sitter-cli);
-- install.sh waits for this on first run
vim.g.ts_parsers = { "bash", "json", "toml", "xml", "markdown", "markdown_inline", "c_sharp" }
require("nvim-treesitter").install(vim.g.ts_parsers)

vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		if pcall(vim.treesitter.start, ev.buf) then
			vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})

require("treesitter-context").setup({
	max_lines = 5,
	multiline_threshold = 1,
	trim_scope = "inner",
})

-- Editing ---------------------------------------------------------------------

require("nvim-autopairs").setup({})

require("Comment").setup()

-- Surround binds on the gz prefix
for _, m in ipairs({
	{ "i", "<C-g>z", "insert" },
	{ "i", "<C-g>Z", "insert-line" },
	{ "n", "gz", "normal" },
	{ "n", "gZ", "normal-cur" },
	{ "n", "gzz", "normal-line" },
	{ "n", "gZZ", "normal-cur-line" },
	{ "x", "gz", "visual" },
	{ "x", "gZ", "visual-line" },
	{ "n", "gzd", "delete" },
	{ "n", "gzr", "change" },
	{ "n", "gZR", "change-line" },
}) do
	vim.keymap.set(m[1], m[2], "<Plug>(nvim-surround-" .. m[3] .. ")")
end

-- Navigation ------------------------------------------------------------------

require("telescope").setup({
	defaults = {
		file_ignore_patterns = { "node_modules", "%.git/", "dist/", "build/", "target/", "result/" },
		vimgrep_arguments = { "rg", "--color=never", "--no-heading", "--with-filename",
			"--line-number", "--column", "--smart-case", "--hidden" },
	},
	pickers = {
		find_files = { find_command = { "fd", "--type=file", "--hidden", "--exclude=.git" } },
	},
})

-- LSP / formatting ------------------------------------------------------------

-- Server configs come from nvim-lspconfig; xml (lemminx) has no musl build
vim.lsp.enable({ "bashls", "jsonls", "taplo", "marksman", "roslyn_ls" })

local conform = require("conform")
local format_on_save = false
conform.setup({
	formatters_by_ft = {
		sh = { "shfmt" },
		bash = { "shfmt" },
		json = { "deno_fmt" },
		toml = { "taplo" },
		xml = { "xmllint" },
		markdown = { "deno_fmt" },
		cs = { "csharpier" },
	},
	format_on_save = function()
		if format_on_save then
			return { lsp_format = "fallback" }
		end
	end,
})

require("trouble").setup()

-- Tools -----------------------------------------------------------------------

require("toggleterm").setup({ open_mapping = "<C-t>", direction = "horizontal" })
local lazygit = require("toggleterm.terminal").Terminal:new({
	cmd = "lazygit",
	direction = "float",
	hidden = true,
})

require("render-markdown").setup({})

-- Keymaps ---------------------------------------------------------------------

local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- Keep cursor centered
map({ "n", "v" }, "<C-d>", "<C-d>zz")
map({ "n", "v" }, "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "(", "(zzzv")
map("n", ")", ")zzzv")

-- Move/join lines
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map("n", "J", "mzJ`z")

-- Leader binds
map("n", "<leader>pv", "<Cmd>Ex<CR>", "Netrw")
map("n", "<leader>u", "<Cmd>UndotreeToggle<CR>", "Undotree")
map("n", "<leader>md", "<Cmd>MarkdownPreviewToggle<CR>", "Markdown preview")
map("n", "<leader>gg", function() lazygit:toggle() end, "Lazygit")


-- Telescope
local tb = require("telescope.builtin")
map("n", "<leader>ff", tb.find_files, "Find files")
map("n", "<leader>fg", tb.live_grep, "Live grep")
map("n", "<leader>fb", tb.buffers, "Buffers")
map("n", "<leader>fh", tb.help_tags, "Help tags")
map("n", "<leader>ft", "<Cmd>Telescope<CR>", "Telescope")
map("n", "<leader>fr", tb.resume, "Resume")
map("n", "<leader>fs", tb.treesitter, "Treesitter symbols")
map("n", "<leader>fvcw", tb.git_commits, "Git commits")
map("n", "<leader>fvcb", tb.git_bcommits, "Git buffer commits")
map("n", "<leader>fvb", tb.git_branches, "Git branches")
map("n", "<leader>fvs", tb.git_status, "Git status")
map("n", "<leader>fvx", tb.git_stash, "Git stash")
map("n", "<leader>flsb", tb.lsp_document_symbols, "Document symbols")
map("n", "<leader>flsw", tb.lsp_workspace_symbols, "Workspace symbols")
map("n", "<leader>flr", tb.lsp_references, "References")
map("n", "<leader>fli", tb.lsp_implementations, "Implementations")
map("n", "<leader>flD", tb.lsp_definitions, "Definitions")
map("n", "<leader>flt", tb.lsp_type_definitions, "Type definitions")
map("n", "<leader>fld", tb.diagnostics, "Diagnostics")

-- LSP
map("n", "<leader>lgd", vim.lsp.buf.definition, "Go to definition")
map("n", "<leader>lgD", vim.lsp.buf.declaration, "Go to declaration")
map("n", "<leader>lgt", vim.lsp.buf.type_definition, "Go to type")
map("n", "<leader>lgi", vim.lsp.buf.implementation, "List implementations")
map("n", "<leader>lgr", vim.lsp.buf.references, "List references")
map("n", "<leader>lgn", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
map("n", "<leader>lgp", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
map("n", "<leader>le", vim.diagnostic.open_float, "Diagnostic float")
map("n", "<leader>lH", vim.lsp.buf.document_highlight, "Document highlight")
map("n", "<leader>lS", vim.lsp.buf.document_symbol, "Document symbols")
map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
map("n", "<leader>lwl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, "List workspace folders")
map("n", "<leader>lws", vim.lsp.buf.workspace_symbol, "Workspace symbols")
map("n", "<leader>lh", vim.lsp.buf.hover, "Hover")
map("n", "<leader>ls", vim.lsp.buf.signature_help, "Signature help")
map("n", "<leader>ln", vim.lsp.buf.rename, "Rename")
map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
map({ "n", "v" }, "<leader>lf", function() conform.format({ lsp_format = "fallback" }) end, "Format")
map("n", "<leader>ltf", function()
	format_on_save = not format_on_save
	vim.notify("Format on save " .. (format_on_save and "on" or "off"))
end, "Toggle format on save")

-- Trouble
map("n", "<leader>ld", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", "Document diagnostics")
map("n", "<leader>lwd", "<Cmd>Trouble diagnostics toggle<CR>", "Workspace diagnostics")
map("n", "<leader>lr", "<Cmd>Trouble lsp_references toggle<CR>", "LSP references")
map("n", "<leader>xq", "<Cmd>Trouble qflist toggle<CR>", "Quickfix")
map("n", "<leader>xl", "<Cmd>Trouble loclist toggle<CR>", "Location list")
map("n", "<leader>xs", "<Cmd>Trouble symbols toggle<CR>", "Symbols")
