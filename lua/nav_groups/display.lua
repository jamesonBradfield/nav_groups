-- display.lua - Display formats and rendering for nav_groups

local state = require("nav_groups.state")
local config = require("nav_groups.config")
local utils = require("nav_groups.utils")

local M = {}

-- Display format functions
local formats = {}

-- Default: [group_id] 1 [2] 3 4
function formats.default(group_id, group, current_idx)
	if #group == 0 then
		return "[" .. group_id .. "]"
	end
	local parts = {}
	for i = 1, #group do
		if i == current_idx then
			table.insert(parts, "[" .. i .. "]")
		else
			table.insert(parts, tostring(i))
		end
	end

	return "[" .. group_id .. "] " .. table.concat(parts, " ")
end

-- Minimal: 📂1 ▶2/4 or 📂1 ●4
function formats.minimal(group_id, group, current_idx)
	local cfg = config.get()
	local group_icon = cfg.icons.group or "G"
	local current_icon = cfg.icons.current or "▶"
	local other_icon = cfg.icons.other or "●"
	local empty_icon = cfg.icons.empty or "○"

	if #group == 0 then
		return group_icon .. group_id .. " " .. empty_icon
	end

	if current_idx then
		return string.format("%s%d %s%d/%d", group_icon, group_id, current_icon, current_idx, #group)
	else
		return string.format("%s%d %s%d", group_icon, group_id, other_icon, #group)
	end
end

-- Compact: G1:2/4 or G1:4
function formats.compact(group_id, group, current_idx)
	if #group == 0 then
		return "G" .. group_id .. ":0"
	end

	if current_idx then
		return string.format("G%d:%d/%d", group_id, current_idx, #group)
	else
		return string.format("G%d:%d", group_id, #group)
	end
end

-- Get status for statusline/lualine
function M.get_status()
	state.ensure_initialized()

	local group_id = state.get_window_group()
	local group = state.groups[group_id]
	local current_file = utils.get_current_file()
	local current_idx = current_file and utils.find_file_in_group(group, current_file)

	local cfg = config.get()

	-- Use custom function if provided
	if type(cfg.display_format) == "function" then
		return cfg.display_format(group_id, group, current_idx)
	end

	-- Use built-in format
	local format_func = formats[cfg.display_format] or formats.default
	return format_func(group_id, group, current_idx)
end

-- Build content lines for floating window
function M.build_float_content(current_group_id, current_file)
	local lines = {}
	local highlights = {} -- Array of {line, hl_group, col_start, col_end}

	for group_idx, group in ipairs(state.groups) do
		local is_current_group = (group_idx == current_group_id)
		local group_header =
			string.format("%s Group %d  (%d files)", is_current_group and "📂" or " ", group_idx, #group)
		table.insert(lines, group_header)

		-- Highlight current group header
		if is_current_group then
			table.insert(highlights, {
				line = #lines - 1, -- 0-indexed
				hl_group = "CursorLine",
				col_start = 0,
				col_end = -1,
			})
		end

		if #group == 0 then
			table.insert(lines, "  (empty)")
		else
			for file_idx, filepath in ipairs(group) do
				local filename = vim.fn.fnamemodify(filepath, ":t")
				local current_file_idx = current_file and utils.find_file_in_group(group, current_file)
				local is_current_file = is_current_group and (file_idx == current_file_idx)

				local prefix = is_current_file and "▶" or "○"
				local line = string.format("  %d. %s %s", file_idx, prefix, filename)
				table.insert(lines, line)

				-- Highlight current file
				if is_current_file then
					table.insert(highlights, {
						line = #lines - 1,
						hl_group = "Visual",
						col_start = 0,
						col_end = -1,
					})
				end
			end
		end

		-- Add separator between groups
		if group_idx < #state.groups then
			table.insert(lines, "")
		end
	end

	return lines, highlights
end

-- Calculate adaptive height for floating window
function M.calculate_adaptive_height()
	local cfg = config.get().window
	local height = 0

	-- Add lines for each group
	for _, group in ipairs(state.groups) do
		height = height + 1 -- Group header
		if #group == 0 then
			height = height + 1 -- "(empty)" line
		else
			height = height + #group -- File lines
		end
		height = height + 1 -- Separator between groups
	end

	-- Remove last separator
	if #state.groups > 0 then
		height = height - 1
	end

	-- Add padding
	height = height + (cfg.padding or 2)

	-- Apply min/max constraints
	local min_height = cfg.min_height or 5
	local max_height = cfg.max_height or 30

	-- Handle fractional max_height
	if type(max_height) == "number" and max_height <= 1 then
		max_height = math.floor(vim.o.lines * max_height)
	end

	height = math.max(min_height, math.min(height, max_height))
	return height
end

-- Calculate adaptive width for floating window
function M.calculate_adaptive_width()
	local cfg = config.get().window
	local max_len = 0

	-- Account for title
	local title = cfg.title or " Navigation Groups "
	max_len = #title

	-- Check each group's content
	for group_idx, group in ipairs(state.groups) do
		-- Group header: "📂 Group 1  (10 files)"
		local header_len = #string.format("📂 Group %d  (%d files)", group_idx, #group)
		max_len = math.max(max_len, header_len)

		if #group > 0 then
			for file_idx, filepath in ipairs(group) do
				local filename = vim.fn.fnamemodify(filepath, ":t")
				-- File line: "  1. ▶  filename.txt"
				local line_len = #string.format("  %d. ▶  %s", file_idx, filename)
				max_len = math.max(max_len, line_len)
			end
		else
			max_len = math.max(max_len, 10)
		end
	end

	-- Add padding
	local width = max_len + (cfg.padding or 4)

	-- Apply min/max constraints
	local min_width = cfg.min_width or 25
	local max_width = cfg.max_width or 60

	-- Handle fractional max_width
	if type(max_width) == "number" and max_width <= 1 then
		max_width = math.floor(vim.o.columns * max_width)
	end

	width = math.max(min_width, math.min(width, max_width))
	return width
end

return M
