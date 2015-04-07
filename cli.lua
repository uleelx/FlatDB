local flatdb = require("flatdb")
local pp = require("pp")

local function split(s, sep, maxsplit, plain)
	assert(sep and sep ~= "")
	maxsplit = maxsplit or 1/0
	local items = {}
	if #s > 0 then
		local init = 1
		for i = 1, maxsplit do
			local m, n = s:find(sep, init, plain)
			if m and m <= n then
				table.insert(items, s:sub(init, m - 1))
				init = n + 1
			else
				break
			end
		end
		table.insert(items, s:sub(init))
	end
	return items
end

local db = assert(flatdb("./db"))
local page = "0"

local COMMANDS = {
	SAVE = function(key)
		print(db:save(key) and "OK" or "ERROR")
	end,
	TOUCH = function(key)
		if not key then
			print("USAGE: TOUCH page")
			return
		end
		if not db[key] then
			db[key] = {}
		end
		print("OK")
	end,
	SELECT = function(key)
		if not key then
			print("USAGE: SELECT page")
			return
		end
		if tonumber(key) and tonumber(key) < 16 then
			if not db[key] then
				db[key] = {}
			end
		end
		if db[key] then
			page = key
			print("OK")
		else
			print("ERROR: database not found, try using 'TOUCH' command first")
		end
	end,
	GET = function(key)
		if not key then
			print("USAGE: GET key")
			return
		end
		print(pp.format(db[page][key]))
	end,
	SET = function(key, value)
		if not key then
			print("USAGE: SET key value")
			return
		end
		local ok, tmp = pcall(load("return "..tostring(value), "=(load)", "t", db))
		db[page][key] = ok and tmp or value
		print("OK")
	end,
	INCR = function(key)
		if not key then
			print("USAGE: INCR key")
			return
		end
		if not db[page][key] then
			db[page][key] = 0
		end
		db[page][key] = db[page][key] + 1
		print("OK")
	end,
	DECR = function(key)
		if not key then
			print("USAGE: DECR key")
			return
		end
		if not db[page][key] then
			db[page][key] = 0
		end
		db[page][key] = db[page][key] - 1
		print("OK")
	end,
	RPUSH = function(key, value)
		if not key then
			print("USAGE: RPUSH list value")
			return
		end
		if not db[page][key] then
			db[page][key] = {}
		end
		table.insert(db[page][key], value)
		print(#db[page][key])
	end,
	LPUSH = function(key, value)
		if not key then
			print("USAGE: LPUSH list value")
			return
		end
		if not db[page][key] then
			db[page][key] = {}
		end
		table.insert(db[page][key], 1, value)
		print(#db[page][key])
	end,
	RPOP = function(key)
		if not key then
			print("USAGE: RPOP list")
			return
		end
		if db[page][key] then
			print(table.remove(db[page][key]))
		else
			print("nil")
		end
	end,
	LPOP = function(key)
		if not key then
			print("USAGE: LPOP list")
			return
		end
		if db[page][key] then
			print(table.remove(db[page][key], 1))
		else
			print("nil")
		end
	end,
	LLEN = function(key)
		if not key then
			print("USAGE: LLEN list")
			return
		end
		print(db[page][key] and #db[page][key] or 0)
	end,
	LINDEX = function(key, value)
		if not key and not value then
			print("USAGE: LINDEX list index")
			return
		end
		if db[page][key] then
			local i = tonumber(value)
			if i < 0 then i = i + #db[page][key] end
			i = i + 1
			print(db[page][key][i])
		else
			print("nil")
		end
	end
}

local function handle(input)
	local c = split(input, " ", 2)
	local cmd, key, value = string.upper(c[1]), c[2], c[3]
	if COMMANDS[cmd] then
		COMMANDS[cmd](key, value)
	else
		print("ERROR: command not found")
	end
end

local function main()
	if not db["0"] then
		db["0"] = {}
	end
	io.stdout:setvbuf("no")
	while true do
		local prefix = page == "0" and "" or ("["..page.."]")
		io.write("flatdb"..prefix.."> ")
		local input = io.read("*l")
		if string.upper(input) == "EXIT" or string.upper(input) == "QUIT" then
			break
		end
		handle(input)
	end
end

main()
