-- config.lua - Configuration management for nav_groups

local M = {}

-- Default configuration
M.defaults = {
	-- Display format: 'default', 'minimal', or custom function
	display_format = "default",

	-- Custom separator for context format
	separator = "|",

	-- Icons (set to '' or false to disable)
	icons = {
		group = "📂",
		current = "▶",
		other = "●",
		empty = "○",
	},

	-- Window styling
	window = {
		position = "right", -- "right", "left", "top", "bottom"
		width = "auto", -- Width in columns, fraction like 0.3, or "auto" for adaptive
		height = 1.0, -- Height (1.0 = full height, "auto" = adaptive, or specific number)
		border = "rounded", -- "rounded", "double", "solid", "shadow", etc.
		title = " Navigation Groups ",
		title_pos = "center", -- "left", "center", "right"
		backdrop = false, -- Dim background (requires snacks.nvim)

		-- Auto-open settings
		auto_open = false, -- Automatically open persistent float
		auto_open_on_setup = false, -- Open float when plugin loads
		auto_open_on_add = false, -- Open float when file is added
		auto_close_on_empty = false, -- Close float when all groups are empty

		-- Adaptive dimensions settings (when width/height = "auto")
		min_width = 25,
		max_width = 60,
		min_height = 5,
		max_height = 30,
		padding = 2,

		-- Custom highlight groups
		highlights = {
			normal = "Normal",
			border = "FloatBorder",
			title = "FloatTitle",
		},
	},

	-- Session management
	session = {
		enabled = true, -- Enable automatic session management
		autosave = true, -- Automatically save on changes
		autoload = true, -- Automatically load on project enter
		save_on_exit = true, -- Save when Neovim exits
		session_dir = nil, -- Will be set to vim.fn.stdpath("data")/nav_groups/sessions if nil
	},

	-- Enable default keymaps
	keymaps = true,
}

-- Current configuration (merged with user options)
M.options = nil

-- Merge user configuration
function M.setup(user_opts)
	user_opts = user_opts or {}
	M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_opts)
	return M.options
end

-- Get current configuration
function M.get()
	-- Return options if already set, otherwise return defaults
	if M.options then
		return M.options
	end
	return M.defaults
end

return M
