-- session.lua - Project-based session persistence for nav_groups

local state = require("nav_groups.state")
local config = require("nav_groups.config")
local utils = require("nav_groups.utils")

local M = {}

-- Current project root and session file
M.current_project = nil
M.current_session_file = nil

-- Get session file path for a project
local function get_session_file(project_root)
	local cfg = config.get().session
	local session_dir = cfg.session_dir

	-- Compute default session_dir if not set (handle both nil and v:null)
	if not session_dir or session_dir == vim.NIL then
		session_dir = vim.fn.stdpath("data") .. "/nav_groups/sessions"
	end

	-- Create session directory if it doesn't exist
	vim.fn.mkdir(session_dir, "p")

	-- Create a safe filename from project path
	local identifier = utils.project_identifier(project_root)
	return session_dir .. "/" .. identifier .. ".json"
end

-- Serialize groups to JSON-compatible format
local function serialize_groups(groups)
	local data = {
		version = 1,
		project_root = M.current_project,
		timestamp = os.time(),
		groups = groups,
	}
	return vim.json.encode(data)
end

-- Deserialize groups from JSON
local function deserialize_groups(json_str)
	local ok, data = pcall(vim.json.decode, json_str)
	if not ok then
		return nil
	end

	-- Validate structure
	if type(data) ~= "table" or type(data.groups) ~= "table" then
		return nil
	end

	return data.groups
end

-- Save current session
function M.save_session(project_root)
	project_root = project_root or M.current_project

	if not project_root then
		vim.notify("No project detected for session save", vim.log.levels.WARN)
		return false
	end

	local session_file = get_session_file(project_root)
	local groups = state.get_all_groups()

	-- Don't save if all groups are empty
	local has_content = false
	for _, group in ipairs(groups) do
		if #group > 0 then
			has_content = true
			break
		end
	end

	if not has_content then
		-- Remove session file if it exists
		if vim.fn.filereadable(session_file) == 1 then
			vim.fn.delete(session_file)
		end
		return true
	end

	-- Serialize and save
	local json_str = serialize_groups(groups)
	local file = io.open(session_file, "w")
	if not file then
		vim.notify("Failed to save session to " .. session_file, vim.log.levels.ERROR)
		return false
	end

	file:write(json_str)
	file:close()

	M.current_session_file = session_file
	return true
end

-- Load session for project
function M.load_session(project_root)
	project_root = project_root or utils.detect_project_root()

	if not project_root then
		return false
	end

	local session_file = get_session_file(project_root)

	-- Check if session file exists
	if vim.fn.filereadable(session_file) ~= 1 then
		return false
	end

	-- Read and deserialize
	local file = io.open(session_file, "r")
	if not file then
		return false
	end

	local json_str = file:read("*all")
	file:close()

	local groups = deserialize_groups(json_str)
	if not groups then
		vim.notify("Failed to load session from " .. session_file, vim.log.levels.WARN)
		return false
	end

	-- Apply loaded groups
	state.set_all_groups(groups)

	M.current_project = project_root
	M.current_session_file = session_file

	vim.notify("Loaded session for " .. vim.fn.fnamemodify(project_root, ":t"), vim.log.levels.INFO)
	return true
end

-- Auto-save session
function M.autosave()
	local cfg = config.get().session
	if not cfg.enabled or not cfg.autosave then
		return
	end

	if M.current_project then
		M.save_session(M.current_project)
	end
end

-- Initialize session management
function M.setup()
	local cfg = config.get().session

	if not cfg.enabled then
		return
	end

	-- Detect and load project session on startup
	if cfg.autoload then
		local project_root = utils.detect_project_root()
		if project_root then
			M.current_project = project_root
			M.load_session(project_root)
		end
	end

	-- Auto-save on state changes
	if cfg.autosave then
		state.on_change(function()
			-- Debounce saves
			if M.save_timer then
				M.save_timer:stop()
			end
			M.save_timer = vim.defer_fn(function()
				M.autosave()
			end, 1000) -- Save 1 second after last change
		end)
	end

	-- Save on exit
	if cfg.save_on_exit then
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				if M.save_timer then
					M.save_timer:stop()
				end
				M.save_session()
			end,
		})
	end

	-- Watch for project changes (directory change)
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			local new_project = utils.detect_project_root()
			if new_project ~= M.current_project then
				-- Save old project
				if M.current_project and cfg.autosave then
					M.save_session(M.current_project)
				end

				-- Load new project
				M.current_project = new_project
				if cfg.autoload then
					M.load_session(new_project)
				end
			end
		end,
	})
end

-- List all sessions
function M.list_sessions()
	local cfg = config.get().session
	local session_dir = cfg.session_dir

	-- Compute default session_dir if not set (handle both nil and v:null)
	if not session_dir or session_dir == vim.NIL then
		session_dir = vim.fn.stdpath("data") .. "/nav_groups/sessions"
	end

	if vim.fn.isdirectory(session_dir) ~= 1 then
		return {}
	end

	local sessions = {}
	local files = vim.fn.readdir(session_dir)

	for _, filename in ipairs(files) do
		if vim.endswith(filename, ".json") then
			local filepath = session_dir .. "/" .. filename
			local file = io.open(filepath, "r")
			if file then
				local json_str = file:read("*all")
				file:close()

				local ok, data = pcall(vim.json.decode, json_str)
				if ok and data.project_root then
					table.insert(sessions, {
						project_root = data.project_root,
						filepath = filepath,
						timestamp = data.timestamp,
						group_count = #data.groups,
					})
				end
			end
		end
	end

	-- Sort by timestamp (most recent first)
	table.sort(sessions, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	return sessions
end

-- Delete a session
function M.delete_session(project_root)
	if not project_root then
		return false
	end

	local session_file = get_session_file(project_root)
	if vim.fn.filereadable(session_file) == 1 then
		vim.fn.delete(session_file)
		vim.notify("Deleted session for " .. vim.fn.fnamemodify(project_root, ":t"), vim.log.levels.INFO)
		return true
	end

	return false
end

return M
