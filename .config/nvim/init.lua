-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Global & Editor Options
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local options = {
	tabstop = 4,
	shiftwidth = 4,
	softtabstop = 4,
	expandtab = true,
	number = true,
	relativenumber = true,
	termguicolors = true, -- Highly recommended for tokyonight
}

for k, v in pairs(options) do
	vim.opt[k] = v
end

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		{
			"folke/tokyonight.nvim",
			lazy = false,
			priority = 1000,
			opts = { style = "night" },
			config = function(_, opts)
				require("tokyonight").setup(opts)
				vim.cmd.colorscheme("tokyonight")
			end,
		},
		{
			"romus204/tree-sitter-manager.nvim",
			cmd = { "TSManagerInstall", "TSManagerUninstall" }, -- Lazy load on commands if applicable
			opts = {},
		},
		{
			"mason-org/mason-lspconfig.nvim",
			event = { "BufReadPre", "BufNewFile" },
			dependencies = {
				{ "mason-org/mason.nvim", opts = {} },
				"neovim/nvim-lspconfig",
			},
			opts = {},
		},
		{
			"hrsh7th/nvim-cmp",
			event = "InsertEnter",
			dependencies = {
				{
					"L3MON4D3/LuaSnip",
					build = "make install_jsregexp",
					dependencies = { "rafamadriz/friendly-snippets" },
					config = function()
						require("luasnip.loaders.from_vscode").lazy_load()
					end,
				},
				"saadparwaiz1/cmp_luasnip",
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-cmdline",
			},
			config = function()
				local cmp = require("cmp")
				local luasnip = require("luasnip")

				cmp.setup({
					snippet = {
						expand = function(args)
							luasnip.lsp_expand(args.body)
						end,
					},
					mapping = cmp.mapping.preset.insert({
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),
						["<C-Space>"] = cmp.mapping.complete(),
						["<C-e>"] = cmp.mapping.abort(),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
						["<Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_next_item()
							elseif luasnip.expand_or_jumpable() then
								luasnip.expand_or_jump()
							else
								fallback()
							end
						end, { "i", "s" }),
						["<S-Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_prev_item()
							elseif luasnip.jumpable(-1) then
								luasnip.jump(-1)
							else
								fallback()
							end
						end, { "i", "s" }),
					}),
					sources = cmp.config.sources({
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
					}, {
						{ name = "buffer" },
						{ name = "path" },
					}),
				})

				cmp.setup.cmdline({ "/", "?" }, {
					mapping = cmp.mapping.preset.cmdline(),
					sources = { { name = "buffer" } },
				})

				cmp.setup.cmdline(":", {
					mapping = cmp.mapping.preset.cmdline(),
					sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
					matching = { disallow_symbol_nonprefix_matching = false },
				})
			end,
		},
		{
			"nvim-tree/nvim-tree.lua",
			keys = {
				{ "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Tree" },
			},
			opts = {}, -- Automatically calls require("nvim-tree").setup(opts)
		},
		{
			"ej-shafran/compile-mode.nvim",
			version = "^5.0.0",
			dependencies = {
				"nvim-lua/plenary.nvim",
				"m00qek/baleia.nvim",
			},
			keys = {
				{ "<leader>cc", "<cmd>Compile<cr>", desc = "Run Compile" },
				{ "<leader>cn", "<cmd>NextError<cr>", desc = "Next Compile Error" },
			},
			config = function()
				vim.g.compile_mode = {
					input_word_completion = true,
					baleia_setup = true,
				}
			end,
		},
		{
			"stevearc/conform.nvim",
			keys = {
				{
					"<leader>f",
					function()
						require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 500 })
					end,
					mode = { "n", "v" },
					desc = "Format file or range",
				},
			},
			opts = {
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black" },
					javascript = { "prettier" },
					c = { "clang-format" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			},
		},
		{
			"nvim-lualine/lualine.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons", "folke/tokyonight.nvim" },
			opts = {
				options = { theme = "tokyonight" },
			},
		},
		{
			"ibhagwan/fzf-lua",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			keys = {
				{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
				{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep (Search Text)" },
				{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find Buffers" },
				{ "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Find Help Tags" },
				{ "<leader>fa", "<cmd>FzfLua<cr>", desc = "FzfLua Generic Menu" },
			},
			opts = {
				-- 1. Use the 'builtin' previewer for a massive speed boost over heavy buffers
				previewers = {
					builtin = {
						syntax = false, -- Keep syntax highlighting
						limit_b = 1024 * 1024, -- Don't preview files larger than 1MB
					},
				},
			},
		},
	},
	install = { colorscheme = { "tokyonight", "habamax" } }, -- Prefer tokyonight for fallbacks
	checker = { enabled = true },
	performance = {
		rtp = {
			-- Disable unneeded built-in vim plugins to boost startup speed
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin", -- Remove if you prefer Netrw over nvim-tree
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
