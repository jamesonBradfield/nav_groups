-- utils.lua - Utility functions for nav_groups

local M = {}

-- Get current file path (relative to cwd if possible)
function M.get_current_file()
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return nil
	end
	-- Make path relative to cwd if possible
	local cwd = vim.fn.getcwd()
	if vim.startswith(filepath, cwd) then
		filepath = filepath:sub(#cwd + 2) -- +2 to skip the trailing slash
	end
	return filepath
end

-- Find index of file in group
function M.find_file_in_group(group, filepath)
	for i, file in ipairs(group) do
		if file == filepath then
			return i
		end
	end
	return nil
end

-- Detect project root directory
function M.detect_project_root()
	local indicators = {
		".git",
		".nvim",
		".project",
		"package.json",
		"Cargo.toml",
		"go.mod",
		"pyproject.toml",
	}

	local current_dir = vim.fn.getcwd()
	local home = vim.fn.expand("~")

	-- Walk up directory tree
	local dir = current_dir
	while dir ~= "/" and dir ~= home do
		for _, indicator in ipairs(indicators) do
			local path = dir .. "/" .. indicator
			if vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1 then
				return dir
			end
		end
		dir = vim.fn.fnamemodify(dir, ":h")
	end

	-- Fall back to current directory
	return current_dir
end

-- Create a safe project identifier from path
function M.project_identifier(path)
	-- Replace path separators and special chars with underscores
	local identifier = path:gsub("[/\\:.]", "_")
	-- Remove leading/trailing underscores
	identifier = identifier:gsub("^_+", ""):gsub("_+$", "")
	return identifier
end

-- Deep copy a table
function M.deep_copy(orig)
	local copy
	if type(orig) == "table" then
		copy = {}
		for k, v in pairs(orig) do
			copy[k] = M.deep_copy(v)
		end
	else
		copy = orig
	end
	return copy
end

return M
