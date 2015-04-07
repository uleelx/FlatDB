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

local function handle(input)
	local c = split(input, " ", 2)
	local cmd, key, value = string.upper(c[1]), c[2], c[3]
	if cmd == "SAVE" then
		print(db:save(key) and "OK" or "ERROR")
	elseif cmd == "TOUCH" then
		if not db[key] then
			db[key] = {}
		end
		print("OK")
	elseif cmd == "SELECT" then
		if tonumber(key) and tonumber(key) < 16 then
			if not db[key] then
				db[key] = {}
			end
		end
		if db[key] then
			page = key
			print("OK")
		else
			print("ERROR")
		end
	elseif cmd == "GET" then
		print(pp.format(db[page][key]))
	elseif cmd == "SET" then
		local ok, tmp = pcall(load("return "..tostring(value), "=(load)", "t", db))
		db[page][key] = ok and tmp or value
		print("OK")
	elseif cmd == "INCR" then
		if not db[page][key] then
			db[page][key] = 0
		end
		db[page][key] = db[page][key] + 1
		print("OK")
	elseif cmd == "DECR" then
		if not db[page][key] then
			db[page][key] = 0
		end
		db[page][key] = db[page][key] - 1
		print("OK")
	elseif cmd == "RPUSH" then
		if not db[page][key] then
			db[page][key] = {}
		end
		table.insert(db[page][key], value)
		print(#db[page][key])
	elseif cmd == "LPUSH" then
		if not db[page][key] then
			db[page][key] = {}
		end
		table.insert(db[page][key], 1, value)
		print(#db[page][key])
	elseif cmd == "RPOP" then
		if not db[page][key] then
			db[page][key] = {}
		end
		print(table.remove(db[page][key], value))
	elseif cmd == "LPOP" then
		if not db[page][key] then
			db[page][key] = {}
		end
		print(table.remove(db[page][key], 1))
	elseif cmd == "LLEN" then
		print(db[page][key] and #db[page][key] or 0)
	elseif cmd == "LINDEX" then
		if db[page][key] then
			local i = tonumber(value)
			if i < 0 then i = i + #db[page][key] end
			i = i + 1
			print(db[page][key][i])
		else
			print("nil")
		end
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
