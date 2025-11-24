-- init.lua - Main entry point for nav_groups plugin

local M = {}

-- Safely load modules with better error messages
local function safe_require(module_name)
	local ok, module = pcall(require, module_name)
	if not ok then
		error(string.format("Failed to load module '%s': %s", module_name, module), 2)
	end
	return module
end

-- Import modules
local config = safe_require("nav_groups.config")
local state = safe_require("nav_groups.state")
local actions = safe_require("nav_groups.actions")
local display = safe_require("nav_groups.display")
local float = safe_require("nav_groups.float")
local session = safe_require("nav_groups.session")

-- Re-export public API from modules
M.config = config.get

-- State API
M.add_to_group = state.add_to_group
M.remove_from_group = state.remove_from_group
M.has_file = state.has_file
M.get_file_index = state.get_file_index
M.get_group = state.get_group
M.get_all_groups = state.get_all_groups
M.get_group_count = state.get_group_count
M.get_window_group = state.get_window_group
M.set_window_group = state.set_window_group

-- Action API
M.add_file = actions.add_file
M.remove_file = actions.remove_file
M.next_file = actions.next_file
M.prev_file = actions.prev_file
M.goto_file = actions.goto_file
M.next_group = actions.next_group
M.prev_group = actions.prev_group
M.goto_group = actions.goto_group
M.vsplit_new_group = actions.vsplit_new_group
M.clear_group = actions.clear_group
M.clear_all = actions.clear_all

-- Display API
M.get_status = display.get_status

-- Float API
M.toggle_persistent_float = float.toggle_persistent
M.is_float_open = float.is_open
M.auto_open_float = float.auto_open

-- Session API
M.save_session = session.save_session
M.load_session = session.load_session
M.list_sessions = session.list_sessions
M.delete_session = session.delete_session

-- Setup function
function M.setup(opts)
	opts = opts or {}

	-- Configure
	config.setup(opts)
	state.ensure_initialized()

	-- Setup floating window autocmds
	float.setup_autocmds()

	-- Setup session management
	session.setup()

	-- Auto-open float if configured
	local cfg = config.get().window
	if cfg.auto_open_on_setup then
		vim.defer_fn(function()
			float.auto_open()
		end, 100) -- Small delay to ensure everything is loaded
	end

	-- Create user commands
	vim.api.nvim_create_user_command("NavGroupAdd", M.add_file, {})
	vim.api.nvim_create_user_command("NavGroupRemove", M.remove_file, {})
	vim.api.nvim_create_user_command("NavGroupNext", M.next_file, {})
	vim.api.nvim_create_user_command("NavGroupPrev", M.prev_file, {})
	vim.api.nvim_create_user_command("NavGroupSwitchNext", M.next_group, {})
	vim.api.nvim_create_user_command("NavGroupSwitchPrev", M.prev_group, {})
	vim.api.nvim_create_user_command("NavGroupToggle", M.toggle_persistent_float, {})
	vim.api.nvim_create_user_command("NavGroupVsplit", M.vsplit_new_group, {})
	vim.api.nvim_create_user_command("NavGroupClear", M.clear_group, {})
	vim.api.nvim_create_user_command("NavGroupClearAll", M.clear_all, {})

	-- Session commands
	vim.api.nvim_create_user_command("NavGroupSave", function()
		session.save_session()
	end, {})

	vim.api.nvim_create_user_command("NavGroupLoad", function()
		session.load_session()
	end, {})

	vim.api.nvim_create_user_command("NavGroupSessions", function()
		local sessions = session.list_sessions()
		if #sessions == 0 then
			vim.notify("No saved sessions found", vim.log.levels.INFO)
			return
		end

		print("Saved sessions:")
		for i, s in ipairs(sessions) do
			local project_name = vim.fn.fnamemodify(s.project_root, ":t")
			local timestamp = os.date("%Y-%m-%d %H:%M:%S", s.timestamp)
			print(string.format("%d. %s (%d groups) - %s", i, project_name, s.group_count, timestamp))
		end
	end, {})

	-- Goto commands with arguments
	vim.api.nvim_create_user_command("NavGroupGotoFile", function(opts)
		local index = tonumber(opts.args)
		if index then
			M.goto_file(index)
		else
			vim.notify("Usage: NavGroupGotoFile <index>", vim.log.levels.WARN)
		end
	end, { nargs = 1 })

	vim.api.nvim_create_user_command("NavGroupGotoGroup", function(opts)
		local group_id = tonumber(opts.args)
		if group_id then
			M.goto_group(group_id)
		else
			vim.notify("Usage: NavGroupGotoGroup <group_id>", vim.log.levels.WARN)
		end
	end, { nargs = 1 })

	-- Set up default keymaps if requested
	if config.get().keymaps then
		vim.keymap.set("n", "<leader>ga", M.add_file, { noremap = true, silent = true, desc = "Add file to current group" })
		vim.keymap.set("n", "<leader>gd", M.remove_file, { noremap = true, silent = true, desc = "Remove file from current group" })
		vim.keymap.set("n", "<leader>gn", M.next_file, { noremap = true, silent = true, desc = "Go to next file in group" })
		vim.keymap.set("n", "<leader>gp", M.prev_file, { noremap = true, silent = true, desc = "Go to previous file in group" })
		vim.keymap.set("n", "<leader>g]", M.next_group, { noremap = true, silent = true, desc = "Switch to next group" })
		vim.keymap.set("n", "<leader>g[", M.prev_group, { noremap = true, silent = true, desc = "Switch to previous group" })
		vim.keymap.set("n", "<leader>gt", M.toggle_persistent_float, { noremap = true, silent = true, desc = "Toggle nav groups float" })
		vim.keymap.set("n", "<leader>gv", M.vsplit_new_group, { noremap = true, silent = true, desc = "Open new group in vsplit" })
		vim.keymap.set("n", "<leader>gc", M.clear_group, { noremap = true, silent = true, desc = "Clear current group" })
		vim.keymap.set("n", "<leader>gs", session.save_session, { noremap = true, silent = true, desc = "Save nav groups session" })
		vim.keymap.set("n", "<leader>gl", session.load_session, { noremap = true, silent = true, desc = "Load nav groups session" })

		-- Quick goto keymaps (1-9)
		for i = 1, 9 do
			vim.keymap.set("n", "<leader>g" .. i, function()
				M.goto_file(i)
			end, { noremap = true, silent = true, desc = "Go to file " .. i .. " in group" })
		end
	end
end

return M
