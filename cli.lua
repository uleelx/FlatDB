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
local book = "default"

local function handle(input)
	local c = split(input, " ", 2)
	local cmd, key, value = string.upper(c[1]), c[2], c[3]
	if cmd == "GET" then
		print(pp.format(db[book][key]))
	elseif cmd == "SET" then
		local ok, tmp = pcall(load("return "..tostring(value), "=(load)", "t", db))
		db[book][key] = ok and tmp or value
		print("OK")
	elseif cmd == "SAVE" then
		print(db:save(key) and "OK" or "ERROR")
	elseif cmd == "TOUCH" then
		if not db[key] then
			db[key] = {}
		end
		print("OK")
	elseif cmd == "OPEN" then
		if db[key] then
			book = key
			print("OK")
		else
			print("ERROR")
		end
	elseif cmd == "INCR" then
		if not db[book][key] then
			db[book][key] = 0
		end
		db[book][key] = db[book][key] + 1
		print("OK")
	elseif cmd == "DECR" then
		if not db[book][key] then
			db[book][key] = 0
		end
		db[book][key] = db[book][key] - 1
		print("OK")
	end
end

local function main()
	if not db.default then
		db.default = {}
	end
	io.stdout:setvbuf("no")
	while true do
		io.write("> ")
		local input = io.read("*l")
		if string.upper(input) == "EXIT" then
			break
		end
		handle(input)
	end
end

main()
