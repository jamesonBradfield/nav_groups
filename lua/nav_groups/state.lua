-- state.lua - State management for nav_groups

local utils = require("nav_groups.utils")

local M = {}

-- Global state: array of groups, each group is an array of file paths
M.groups = {}

-- Callbacks to notify when state changes
M.on_change_callbacks = {}

-- Initialize with one empty group
function M.ensure_initialized()
	if #M.groups == 0 then
		table.insert(M.groups, {})
	end
end

-- Register a callback for state changes
function M.on_change(callback)
	table.insert(M.on_change_callbacks, callback)
end

-- Notify all callbacks of state change
local function notify_change()
	for _, callback in ipairs(M.on_change_callbacks) do
		callback()
	end
end

-- Get or set the current group index for a window
function M.get_window_group(winid)
	winid = winid or vim.api.nvim_get_current_win()
	local group_id = vim.w[winid].nav_group_id
	if not group_id then
		group_id = 1
		vim.w[winid].nav_group_id = group_id
	end
	return group_id
end

function M.set_window_group(winid, group_id)
	winid = winid or vim.api.nvim_get_current_win()
	vim.w[winid].nav_group_id = group_id
	notify_change()
end

-- Core API: Add file to specific group
function M.add_to_group(filepath, group_id)
	M.ensure_initialized()

	if not filepath or filepath == "" then
		vim.notify("Invalid filepath", vim.log.levels.WARN)
		return false
	end

	if not group_id or group_id < 1 or group_id > #M.groups then
		vim.notify("Invalid group_id: " .. tostring(group_id), vim.log.levels.WARN)
		return false
	end

	local group = M.groups[group_id]

	-- Check if file already exists in group
	if utils.find_file_in_group(group, filepath) then
		return false
	end

	-- Add file to group
	table.insert(group, filepath)

	-- Create next empty group if needed
	if not M.groups[group_id + 1] then
		table.insert(M.groups, {})
	end

	notify_change()
	
	-- Trigger auto-open on add if configured
	M.trigger_auto_open_on_add = true
	
	return true
end

-- Core API: Remove file from specific group
function M.remove_from_group(filepath, group_id)
	M.ensure_initialized()

	if not filepath or filepath == "" then
		vim.notify("Invalid filepath", vim.log.levels.WARN)
		return false
	end

	if not group_id or group_id < 1 or group_id > #M.groups then
		vim.notify("Invalid group_id: " .. tostring(group_id), vim.log.levels.WARN)
		return false
	end

	local group = M.groups[group_id]
	local idx = utils.find_file_in_group(group, filepath)

	if not idx then
		return false
	end

	table.remove(group, idx)
	notify_change()
	return true
end

-- Core API: Check if file exists in specific group
function M.has_file(filepath, group_id)
	M.ensure_initialized()

	if not filepath or filepath == "" then
		return false
	end

	if not group_id or group_id < 1 or group_id > #M.groups then
		return false
	end

	return utils.find_file_in_group(M.groups[group_id], filepath) ~= nil
end

-- Core API: Get index of file in specific group (nil if not found)
function M.get_file_index(filepath, group_id)
	M.ensure_initialized()

	if not filepath or filepath == "" then
		return nil
	end

	if not group_id or group_id < 1 or group_id > #M.groups then
		return nil
	end

	return utils.find_file_in_group(M.groups[group_id], filepath)
end

-- Core API: Get all files in a specific group (returns copy of array)
function M.get_group(group_id)
	M.ensure_initialized()

	if not group_id or group_id < 1 or group_id > #M.groups then
		return nil
	end

	return utils.deep_copy(M.groups[group_id])
end

-- Core API: Get all groups (returns copy of structure)
function M.get_all_groups()
	M.ensure_initialized()
	return utils.deep_copy(M.groups)
end

-- Core API: Set all groups (replaces current state)
function M.set_all_groups(groups)
	M.groups = groups or {}
	M.ensure_initialized()
	notify_change()
end

-- Core API: Get total number of groups
function M.get_group_count()
	M.ensure_initialized()
	return #M.groups
end

-- Clear all groups (reset to single empty group)
function M.clear_all()
	M.groups = {}
	M.ensure_initialized()
	notify_change()
end

return M
