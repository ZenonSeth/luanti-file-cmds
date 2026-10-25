-- Relative is inside the world, absolute requires testcmd in secure.trusted_mods.
local CMD_FILE = "cmds.txt"

local caller = core.settings:get("name") or "singleplayer"

local function log(msg)
	core.log("action", "[testcmd] " .. msg)
end

local function norm(p)
	return (p:gsub("\\", "/"):gsub("/+", "/"):gsub("/$", ""):lower())
end

local function is_inside(p, dir)
	dir = norm(dir)
	return p == dir or p:sub(1, #dir + 1) == dir .. "/"
end

local fio, fos = io, os
local ie = nil
local cmd_path = nil
if CMD_FILE:find("..", 1, true) then
	core.log("error", "[testcmd] CMD_FILE must not contain '..', disabled")
elseif not (CMD_FILE:match("^/") or CMD_FILE:match("^%a:[/\\]") or CMD_FILE:match("^[/\\][/\\]")) then
	cmd_path = core.get_worldpath() .. "/" .. CMD_FILE
else
	ie = core.request_insecure_environment()
	local p = norm(CMD_FILE)
	local mod_data = core.get_mod_data_path():gsub("[/\\][^/\\]*$", "")
	if not ie then
		core.log("error", "[testcmd] absolute CMD_FILE requires testcmd in secure.trusted_mods, disabled")
	elseif is_inside(p, core.get_worldpath()) or is_inside(p, mod_data) then
		core.log("error", "[testcmd] absolute CMD_FILE must be outside the world and mod data paths, disabled")
	else
		cmd_path = CMD_FILE
		fio, fos = ie.io, ie.os
	end
end
ie = nil
local run_path = cmd_path and cmd_path .. ".run"

local function run_lua(_, param)
	local f, err = loadstring("return " .. param)
	if not f then
		f, err = loadstring(param)
	end
	if not f then
		return false, err
	end
	local res = {pcall(f)}
	if not res[1] then
		return false, tostring(res[2])
	end
	local out = {}
	for i = 2, table.maxn(res) do
		out[#out + 1] = dump(res[i])
	end
	return true, table.concat(out, ", ")
end

local function run_line(line)
	local name, param = line:match("^/?(%S+)%s*(.-)%s*$")
	if not name then
		return
	end
	local def = core.registered_chatcommands[name]
	local func = name == "lua" and run_lua or def and def.func
	if not func then
		log("unknown command: /" .. name)
		return
	end
	local cmd = param == "" and "/" .. name or "/" .. name .. " " .. param
	local ok, success, msg = pcall(func, caller, param)
	if not ok then
		log(cmd .. " -> error: " .. tostring(success))
	else
		msg = core.get_translated_string("en", msg or "")
		log(cmd .. " -> " .. tostring(success) .. " " .. msg)
	end
end

local function poll()
	fos.remove(run_path)
	-- Rename first so lines appended mid-read are not lost.
	if not fos.rename(cmd_path, run_path) then
		return
	end
	local f = fio.open(run_path, "r")
	if not f then
		return
	end
	for line in f:lines() do
		run_line(line)
	end
	f:close()
	fos.remove(run_path)
end

if cmd_path then
	local timer = 0
	core.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer >= 0.5 then
			timer = 0
			poll()
		end
	end)
end
