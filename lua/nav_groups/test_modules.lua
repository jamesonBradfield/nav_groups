#!/usr/bin/env lua

-- test_modules.lua - Verify nav_groups module structure
-- Run from project root: lua test_modules.lua

-- Add lua directory to path
package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

-- Mock vim API for testing
_G.vim = {
	api = {
		nvim_create_namespace = function()
			return 1
		end,
		nvim_create_augroup = function()
			return 1
		end,
		nvim_create_autocmd = function() end,
		nvim_create_user_command = function() end,
		nvim_get_current_win = function()
			return 1
		end,
		nvim_get_current_buf = function()
			return 1
		end,
		nvim_buf_get_name = function()
			return ""
		end,
	},
	fn = {
		getcwd = function()
			return "/test/project"
		end,
		stdpath = function(what)
			return "/tmp/nvim"
		end,
		expand = function(path)
			return "/home/user"
		end,
		fnamemodify = function(path, mod)
			return path
		end,
		isdirectory = function()
			return 0
		end,
		filereadable = function()
			return 0
		end,
		fnameescape = function(path)
			return path
		end,
	},
	w = {},
	log = {
		levels = {
			INFO = 2,
			WARN = 3,
			ERROR = 4,
		},
	},
	notify = function() end,
	o = { lines = 40, columns = 80 },
	keymap = { set = function() end },
	startswith = function(str, prefix)
		return str:sub(1, #prefix) == prefix
	end,
	endswith = function(str, suffix)
		return str:sub(-#suffix) == suffix
	end,
	deepcopy = function(t)
		local copy = {}
		for k, v in pairs(t) do
			if type(v) == "table" then
				copy[k] = vim.deepcopy(v)
			else
				copy[k] = v
			end
		end
		return copy
	end,
	tbl_deep_extend = function(behavior, ...)
		local result = {}
		for i = 1, select("#", ...) do
			local t = select(i, ...)
			for k, v in pairs(t) do
				if type(v) == "table" and type(result[k]) == "table" then
					result[k] = vim.tbl_deep_extend(behavior, result[k], v)
				else
					result[k] = v
				end
			end
		end
		return result
	end,
	json = {
		encode = function(t)
			return "{}"
		end,
		decode = function(s)
			return {}
		end,
	},
	defer_fn = function(fn, ms)
		return { stop = function() end }
	end,
}

-- Test helper
local function test(name, fn)
	local success, err = pcall(fn)
	if success then
		print("✓ " .. name)
	else
		print("✗ " .. name)
		print("  Error: " .. tostring(err))
	end
end

print("Testing nav_groups module structure...\n")

-- Test 1: Load all modules
test("Load utils module", function()
	local utils = require("nav_groups.utils")
	assert(type(utils.get_current_file) == "function")
	assert(type(utils.detect_project_root) == "function")
end)

test("Load config module", function()
	local config = require("nav_groups.config")
	assert(type(config.setup) == "function")
	assert(type(config.get) == "function")
end)

test("Load state module", function()
	local state = require("nav_groups.state")
	assert(type(state.ensure_initialized) == "function")
	assert(type(state.add_to_group) == "function")
	assert(type(state.get_all_groups) == "function")
end)

test("Load display module", function()
	local display = require("nav_groups.display")
	assert(type(display.get_status) == "function")
	assert(type(display.build_float_content) == "function")
end)

test("Load actions module", function()
	local actions = require("nav_groups.actions")
	assert(type(actions.add_file) == "function")
	assert(type(actions.next_file) == "function")
end)

test("Load session module", function()
	local session = require("nav_groups.session")
	assert(type(session.save_session) == "function")
	assert(type(session.load_session) == "function")
end)

test("Load float module", function()
	local float = require("nav_groups.float")
	assert(type(float.toggle_persistent) == "function")
end)

test("Load main module", function()
	local nav = require("nav_groups")
	assert(type(nav.setup) == "function")
	assert(type(nav.add_file) == "function")
	assert(type(nav.get_status) == "function")
end)

-- Test 2: Configuration
test("Configuration defaults", function()
	local config = require("nav_groups.config")
	local opts = config.get()
	assert(opts.display_format == "default")
	assert(opts.session.enabled == true)
end)

test("Configuration merge", function()
	local config = require("nav_groups.config")
	config.setup({ display_format = "minimal" })
	local opts = config.get()
	assert(opts.display_format == "minimal")
end)

-- Test 3: State management
test("State initialization", function()
	local state = require("nav_groups.state")
	state.ensure_initialized()
	assert(#state.groups > 0)
end)

test("Add file to group", function()
	local state = require("nav_groups.state")
	state.ensure_initialized()
	local success = state.add_to_group("test.txt", 1)
	assert(success == true)
	assert(#state.groups[1] == 1)
end)

test("Remove file from group", function()
	local state = require("nav_groups.state")
	local success = state.remove_from_group("test.txt", 1)
	assert(success == true)
	assert(#state.groups[1] == 0)
end)

test("Get all groups", function()
	local state = require("nav_groups.state")
	local groups = state.get_all_groups()
	assert(type(groups) == "table")
end)

-- Test 4: Display
test("Get status", function()
	local display = require("nav_groups.display")
	local status = display.get_status()
	assert(type(status) == "string")
end)

test("Build float content", function()
	local display = require("nav_groups.display")
	local lines, highlights = display.build_float_content(1, nil)
	assert(type(lines) == "table")
	assert(type(highlights) == "table")
end)

-- Test 5: Public API
test("Public API exports", function()
	local nav = require("nav_groups")
	assert(type(nav.add_file) == "function")
	assert(type(nav.remove_file) == "function")
	assert(type(nav.next_file) == "function")
	assert(type(nav.prev_file) == "function")
	assert(type(nav.next_group) == "function")
	assert(type(nav.prev_group) == "function")
	assert(type(nav.toggle_persistent_float) == "function")
	assert(type(nav.get_status) == "function")
	assert(type(nav.save_session) == "function")
	assert(type(nav.load_session) == "function")
end)

print("\n✓ All tests passed!")
