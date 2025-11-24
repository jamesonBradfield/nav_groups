-- float.lua - Floating window management for nav_groups

local state = require("nav_groups.state")
local config = require("nav_groups.config")
local display = require("nav_groups.display")
local utils = require("nav_groups.utils")

local M = {}

-- State for persistent floating window
M.persistent = {
	win = nil,
	buf = nil,
}

-- Update the persistent floating window content
local function update_persistent_float()
	if not M.persistent.win then
		return
	end

	-- Get window handle (works for both snacks and regular)
	local win_handle = type(M.persistent.win) == "table" and M.persistent.win.win or M.persistent.win

	if not vim.api.nvim_win_is_valid(win_handle) then
		return
	end

	if not M.persistent.buf or not vim.api.nvim_buf_is_valid(M.persistent.buf) then
		return
	end

	local current_group_id = state.get_window_group()
	local current_file = utils.get_current_file()

	-- Build content
	local lines, highlights = display.build_float_content(current_group_id, current_file)

	-- Update buffer
	vim.api.nvim_buf_set_option(M.persistent.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.persistent.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(M.persistent.buf, "modifiable", false)

	-- Apply highlights
	local ns_id = vim.api.nvim_create_namespace("nav_groups_float")
	vim.api.nvim_buf_clear_namespace(M.persistent.buf, ns_id, 0, -1)

	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(M.persistent.buf, ns_id, hl.hl_group, hl.line, hl.col_start, hl.col_end)
	end

	-- Check if we should auto-close on empty
	local cfg = config.get().window
	if cfg.auto_close_on_empty then
		local has_content = false
		for _, group in ipairs(state.groups) do
			if #group > 0 then
				has_content = true
				break
			end
		end
		if not has_content then
			M.toggle_persistent()
			return
		end
	end

	-- Resize window if using adaptive dimensions
	if vim.api.nvim_win_is_valid(win_handle) then
		local win_config = vim.api.nvim_win_get_config(win_handle)
		local needs_update = false

		-- Update height if adaptive
		if cfg.height == "auto" then
			local new_height = display.calculate_adaptive_height()
			if win_config.height ~= new_height then
				win_config.height = new_height
				needs_update = true
				-- Adjust row for bottom position
				if cfg.position == "bottom" then
					win_config.row = vim.o.lines - new_height - 2
				end
			end
		end

		-- Update width if adaptive
		if cfg.width == "auto" then
			local new_width = display.calculate_adaptive_width()
			if win_config.width ~= new_width then
				win_config.width = new_width
				needs_update = true
				-- Adjust col for right position
				if cfg.position == "right" then
					win_config.col = vim.o.columns - new_width - 2
				elseif cfg.position == "top" or cfg.position == "bottom" then
					win_config.col = math.floor((vim.o.columns - new_width) / 2)
				end
			end
		end

		if needs_update then
			vim.api.nvim_win_set_config(win_handle, win_config)
		end
	end
end

-- Check if float should be auto-opened
local function should_auto_open()
	local cfg = config.get().window
	return cfg.auto_open and not M.persistent.win
end

-- Auto-open the float if configured
function M.auto_open()
	if should_auto_open() then
		M.toggle_persistent()
	end
end

-- Check if float is currently open
function M.is_open()
	if not M.persistent.win then
		return false
	end
	local win_handle = type(M.persistent.win) == "table" and M.persistent.win.win or M.persistent.win
	return vim.api.nvim_win_is_valid(win_handle)
end

-- Register update callbacks
state.on_change(function()
	update_persistent_float()
	
	-- Check for auto-open on add
	if state.trigger_auto_open_on_add then
		state.trigger_auto_open_on_add = false
		local cfg = config.get().window
		if cfg.auto_open_on_add and not M.is_open() then
			M.toggle_persistent()
		end
	end
end)

-- Set up keymaps for buffer
local function setup_buffer_keymaps(buf)
	local opts = { buffer = buf, noremap = true, silent = true }

	-- Close window
	vim.keymap.set("n", "q", function()
		M.toggle_persistent()
	end, opts)

	vim.keymap.set("n", "<Esc>", function()
		M.toggle_persistent()
	end, opts)

	-- Navigate and open files
	vim.keymap.set("n", "<CR>", function()
		local win = M.persistent.win
		local win_handle = type(win) == "table" and win.win or win
		if not vim.api.nvim_win_is_valid(win_handle) then
			return
		end

		local line = vim.api.nvim_win_get_cursor(win_handle)[1]
		local line_idx = 1

		for group_idx, group in ipairs(state.groups) do
			if #group == 0 then
				line_idx = line_idx + 1
			else
				for file_idx, filepath in ipairs(group) do
					if line_idx == line then
						-- Find the most recent non-float window
						for _, w in ipairs(vim.api.nvim_list_wins()) do
							if w ~= win_handle and vim.api.nvim_win_get_config(w).relative == "" then
								vim.api.nvim_set_current_win(w)
								vim.cmd("edit " .. vim.fn.fnameescape(filepath))
								return
							end
						end
					end
					line_idx = line_idx + 1
				end
			end
			line_idx = line_idx + 1
		end
	end, opts)

	-- Add/remove current file
	local actions = require("nav_groups.actions")
	vim.keymap.set("n", "a", actions.add_file, opts)
	vim.keymap.set("n", "d", actions.remove_file, opts)

	-- Navigate between groups
	vim.keymap.set("n", "]", actions.next_group, opts)
	vim.keymap.set("n", "[", actions.prev_group, opts)
end

-- Calculate window dimensions
local function calculate_dimensions()
	local cfg = config.get().window

	local width
	if cfg.width == "auto" then
		width = display.calculate_adaptive_width()
	elseif type(cfg.width) == "number" and cfg.width < 1 then
		width = math.floor(vim.o.columns * cfg.width)
	else
		width = cfg.width
	end

	local height
	if cfg.height == "auto" then
		height = display.calculate_adaptive_height()
	elseif type(cfg.height) == "number" and cfg.height <= 1 then
		height = math.floor(vim.o.lines * cfg.height)
	else
		height = cfg.height
	end

	return width, height
end

-- Calculate window position
local function calculate_position(width, height)
	local cfg = config.get().window
	local col, row

	if cfg.position == "right" then
		col = vim.o.columns - width - 2
		row = 1
	elseif cfg.position == "left" then
		col = 0
		row = 1
	elseif cfg.position == "top" then
		col = math.floor((vim.o.columns - width) / 2)
		row = 0
	elseif cfg.position == "bottom" then
		col = math.floor((vim.o.columns - width) / 2)
		row = vim.o.lines - height - 2
	else
		-- Default to right
		col = vim.o.columns - width - 2
		row = 1
	end

	return col, row
end

-- Toggle persistent floating window
function M.toggle_persistent()
	-- If window exists and is valid, close it
	if M.persistent.win then
		if type(M.persistent.win) == "table" and M.persistent.win.close then
			M.persistent.win:close()
		elseif vim.api.nvim_win_is_valid(M.persistent.win) then
			vim.api.nvim_win_close(M.persistent.win, true)
		end
		M.persistent.win = nil
		M.persistent.buf = nil
		return
	end

	state.ensure_initialized()

	-- Create buffer if needed
	if not M.persistent.buf or not vim.api.nvim_buf_is_valid(M.persistent.buf) then
		M.persistent.buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(M.persistent.buf, "bufhidden", "hide")
		vim.api.nvim_buf_set_option(M.persistent.buf, "filetype", "nav-groups")
	end

	setup_buffer_keymaps(M.persistent.buf)

	local cfg = config.get().window
	local width, height = calculate_dimensions()
	local col, row = calculate_position(width, height)

	-- Try to use snacks.nvim if available
	local has_snacks, snacks = pcall(require, "snacks")
	if has_snacks and snacks.win then
		M.persistent.win = snacks.win({
			buf = M.persistent.buf,
			relative = "editor",
			row = row,
			col = col,
			width = width,
			height = height,
			border = cfg.border,
			title = cfg.title,
			title_pos = cfg.title_pos,
			backdrop = cfg.backdrop,
			enter = false,
			wo = {
				wrap = false,
				cursorline = false,
				winhighlight = string.format(
					"Normal:%s,FloatBorder:%s,FloatTitle:%s",
					cfg.highlights.normal,
					cfg.highlights.border,
					cfg.highlights.title
				),
			},
		})
	else
		-- Fallback to basic nvim floating window
		M.persistent.win = vim.api.nvim_open_win(M.persistent.buf, false, {
			relative = "editor",
			width = width,
			height = height,
			col = col,
			row = row,
			style = "minimal",
			border = cfg.border,
			title = cfg.title,
			title_pos = cfg.title_pos,
		})

		vim.api.nvim_win_set_option(M.persistent.win, "wrap", false)
		vim.api.nvim_win_set_option(M.persistent.win, "cursorline", false)
		vim.api.nvim_win_set_option(
			M.persistent.win,
			"winhighlight",
			string.format(
				"Normal:%s,FloatBorder:%s,FloatTitle:%s",
				cfg.highlights.normal,
				cfg.highlights.border,
				cfg.highlights.title
			)
		)
	end

	-- Initial update
	update_persistent_float()
end

-- Setup autocmds for persistent float updates
function M.setup_autocmds()
	local group = vim.api.nvim_create_augroup("NavGroupsFloatUpdate", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = update_persistent_float,
	})

	vim.api.nvim_create_autocmd("WinEnter", {
		group = group,
		callback = update_persistent_float,
	})
end

return M
