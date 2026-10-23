local cmd_path = core.get_worldpath() .. "/cmds.txt"
local run_path = cmd_path .. ".run"
local caller = core.settings:get("name") or "singleplayer"

local function log(msg)
	core.log("action", "[testcmd] " .. msg)
end

local function run_line(line)
	local name, param = line:match("^/?(%S+)%s*(.-)%s*$")
	if not name then
		return
	end
	local def = core.registered_chatcommands[name]
	if not def then
		log("unknown command: /" .. name)
		return
	end
	local cmd = param == "" and "/" .. name or "/" .. name .. " " .. param
	local ok, success, msg = pcall(def.func, caller, param)
	if not ok then
		log(cmd .. " -> error: " .. tostring(success))
	else
		msg = core.get_translated_string("en", msg or "")
		log(cmd .. " -> " .. tostring(success) .. " " .. msg)
	end
end

local function poll()
	os.remove(run_path)
	-- Rename first so lines appended mid-read are not lost.
	if not os.rename(cmd_path, run_path) then
		return
	end
	local f = io.open(run_path, "r")
	if not f then
		return
	end
	for line in f:lines() do
		run_line(line)
	end
	f:close()
	os.remove(run_path)
end

local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer >= 0.5 then
		timer = 0
		poll()
	end
end)

core.register_chatcommand("lua", {
	params = "<code>",
	description = "Run Lua code, prints returned values",
	privs = {server = true},
	func = function(name, param)
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
	end,
})
