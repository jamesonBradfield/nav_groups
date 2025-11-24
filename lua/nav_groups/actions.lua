-- actions.lua - User-facing actions for nav_groups

local state = require("nav_groups.state")
local utils = require("nav_groups.utils")

local M = {}

-- Add current file to current group
function M.add_file()
	local filepath = utils.get_current_file()
	if not filepath then
		vim.notify("No file in current buffer", vim.log.levels.WARN)
		return
	end

	local group_id = state.get_window_group()
	local success = state.add_to_group(filepath, group_id)

	if success then
		vim.notify("Added to group " .. group_id .. " (" .. #state.groups[group_id] .. " files)", vim.log.levels.INFO)
	else
		vim.notify("File already in group " .. group_id, vim.log.levels.INFO)
	end
end

-- Remove current file from current group
function M.remove_file()
	local filepath = utils.get_current_file()
	if not filepath then
		vim.notify("No file in current buffer", vim.log.levels.WARN)
		return
	end

	local group_id = state.get_window_group()
	local success = state.remove_from_group(filepath, group_id)

	if success then
		vim.notify("Removed from group " .. group_id .. " (" .. #state.groups[group_id] .. " files)", vim.log.levels.INFO)
	else
		vim.notify("File not in group " .. group_id, vim.log.levels.WARN)
	end
end

-- Navigate to next file in current group
function M.next_file()
	state.ensure_initialized()

	local group_id = state.get_window_group()
	local group = state.groups[group_id]

	if #group == 0 then
		vim.notify("Group " .. group_id .. " is empty", vim.log.levels.WARN)
		return
	end

	local current_file = utils.get_current_file()
	local current_idx = current_file and utils.find_file_in_group(group, current_file) or 0

	-- Wrap around to beginning
	local next_idx = (current_idx % #group) + 1
	local next_file = group[next_idx]

	vim.cmd("edit " .. vim.fn.fnameescape(next_file))
end

-- Navigate to previous file in current group
function M.prev_file()
	state.ensure_initialized()

	local group_id = state.get_window_group()
	local group = state.groups[group_id]

	if #group == 0 then
		vim.notify("Group " .. group_id .. " is empty", vim.log.levels.WARN)
		return
	end

	local current_file = utils.get_current_file()
	local current_idx = current_file and utils.find_file_in_group(group, current_file) or 1

	-- Wrap around to end
	local prev_idx = ((current_idx - 2) % #group) + 1
	local prev_file = group[prev_idx]

	vim.cmd("edit " .. vim.fn.fnameescape(prev_file))
end

-- Navigate to specific file index in current group
function M.goto_file(index)
	state.ensure_initialized()

	local group_id = state.get_window_group()
	local group = state.groups[group_id]

	if #group == 0 then
		vim.notify("Group " .. group_id .. " is empty", vim.log.levels.WARN)
		return
	end

	if not index or index < 1 or index > #group then
		vim.notify("Invalid file index: " .. tostring(index), vim.log.levels.WARN)
		return
	end

	local file = group[index]
	vim.cmd("edit " .. vim.fn.fnameescape(file))
end

-- Switch to next group
function M.next_group()
	state.ensure_initialized()

	local current_group = state.get_window_group()
	local next_group = (current_group % #state.groups) + 1

	state.set_window_group(nil, next_group)
	vim.notify("Switched to group " .. next_group, vim.log.levels.INFO)
end

-- Switch to previous group
function M.prev_group()
	state.ensure_initialized()

	local current_group = state.get_window_group()
	local prev_group = ((current_group - 2) % #state.groups) + 1

	state.set_window_group(nil, prev_group)
	vim.notify("Switched to group " .. prev_group, vim.log.levels.INFO)
end

-- Switch to specific group
function M.goto_group(group_id)
	state.ensure_initialized()

	if not group_id or group_id < 1 or group_id > #state.groups then
		vim.notify("Invalid group ID: " .. tostring(group_id), vim.log.levels.WARN)
		return
	end

	state.set_window_group(nil, group_id)
	vim.notify("Switched to group " .. group_id, vim.log.levels.INFO)
end

-- Vsplit with new group context
function M.vsplit_new_group()
	state.ensure_initialized()

	vim.cmd("vsplit")

	-- Find first non-empty group or create new one
	local target_group = nil
	for i, group in ipairs(state.groups) do
		if i ~= state.get_window_group(vim.fn.win_getid(vim.fn.winnr("#"))) and #group > 0 then
			target_group = i
			break
		end
	end

	if not target_group then
		-- Create new empty group
		table.insert(state.groups, {})
		target_group = #state.groups
	end

	state.set_window_group(nil, target_group)
	vim.notify("New window using group " .. target_group, vim.log.levels.INFO)
end

-- Clear current group
function M.clear_group()
	state.ensure_initialized()

	local group_id = state.get_window_group()
	state.groups[group_id] = {}

	vim.notify("Cleared group " .. group_id, vim.log.levels.INFO)
end

-- Clear all groups
function M.clear_all()
	state.clear_all()
	vim.notify("Cleared all groups", vim.log.levels.INFO)
end

return M
