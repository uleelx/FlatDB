local lfs = require("lfs")
local pp = require("pp")

local function isFile(path)
	return lfs.attributes(path, "mode") == "file"
end

local function isDir(path)
	return lfs.attributes(path, "mode") == "directory"
end

local function load_book(path)
	return dofile(path)
end

local function store_book(path, book)
	if type(book) == "table" then
		local f = io.open(path, "wb")
		if f then
			f:write("return ")
			f:write(pp.format(book))
			f:close()
			return true
		end
	end
	return false
end

local pool = {}

local db_funcs = {
	save = function(db, bk)
		if bk then
			if type(bk) == "string" and type(db[bk]) == "table" then
				return store_book(pool[db].."/"..bk, db[bk])
			else
				return false
			end
		end
		for bk, book in pairs(db) do
			store_book(pool[db].."/"..bk, book)
		end
		return true
	end
}

local mt = {
	__index = function(db, k)
		if db_funcs[k] then return db_funcs[k] end
		if isFile(pool[db].."/"..k) then
			db[k] = load_book(pool[db].."/"..k)
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
