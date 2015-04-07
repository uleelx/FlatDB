local lfs = require("lfs")
local pp = require("pp")

local function isFile(path)
	return lfs.attributes(path, "mode") == "file"
end

local function isDir(path)
	return lfs.attributes(path, "mode") == "directory"
end

local function load_page(path)
	return dofile(path)
end

local function store_page(path, page)
	if type(page) == "table" then
		local f = io.open(path, "wb")
		if f then
			f:write("return ")
			f:write(pp.format(page))
			f:close()
			return true
		end
	end
	return false
end

local pool = {}

local db_funcs = {
	save = function(db, p)
		if p then
			if type(p) == "string" and type(db[p]) == "table" then
				return store_page(pool[db].."/"..p, db[p])
			else
				return false
			end
		end
		for p, page in pairs(db) do
			store_page(pool[db].."/"..p, page)
		end
		return true
	end
}

local mt = {
	__index = function(db, k)
		if db_funcs[k] then return db_funcs[k] end
		if isFile(pool[db].."/"..k) then
			db[k] = load_page(pool[db].."/"..k)
		end
		return rawget(db, k)
	end
}

pool.hack = db_funcs

return setmetatable(pool, {
	__mode = "kv",
	__call = function(pool, path)
		if pool[path] then return pool[path] end
		if not isDir(path) then return end
		local db = {}
		setmetatable(db, mt)
		pool[path] = db
		pool[db] = path
		return db
	end
})
