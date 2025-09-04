-- FlatDB v2.0 - Refactored by Gemini
-- A serverless, zero-configuration, NoSQL database engine for Lua.
-- Original by uleelx, refactored to use JSON and improve code quality.

local flatdb = {}
local db_pool = setmetatable({}, {__mode = "v"}) -- Caches DB objects by path: { [path] = db_table }
local path_pool = setmetatable({}, {__mode = "k"}) -- Maps DB objects back to their path: { [db_table] = path }
local db_methods = {} -- Holds methods for DB objects, accessible via flatdb.hack


local json_decode, json_encode
do
    -- https://github.com/rxi/json.lua
    json = require("json")
    json_decode, json_encode = json.decode, json.encode
end

-- =============================================================================
-- Filesystem Utilities
-- =============================================================================

-- Checks if a path is a file.
local function is_file(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Checks if a path is a directory.
-- This trick of renaming a directory to itself is a common Lua idiom.
-- It works because renaming fails on files but succeeds on directories (or returns EPERM).
local function is_dir(path)
    -- Normalize path separator for the check
    local normalized_path = (path .. "/"):gsub("//", "/")
    local ok, _, code = os.rename(normalized_path, normalized_path)
    -- `ok` is true on success, `code` 13 (EPERM) indicates it's a directory on many systems.
    if ok or code == 13 then
        return true
    end
    return false
end

-- =============================================================================
-- Core Database Logic
-- =============================================================================

-- Loads a page from a file and decodes its JSON content.
local function load_page(path)
    local f = io.open(path, "rb")
    if not f then return nil end

    local content = f:read("*a")
    f:close()

    if content == "" then return {} end -- Return empty table for empty file

    local ok, page_data = pcall(json_decode, content)
    if not ok then
        -- Handle JSON decoding error, e.g., print a warning
        print("Warning: Could not decode JSON for page at: " .. path)
        return nil
    end

    return page_data
end

-- Encodes a page (table) to JSON and stores it in a file.
local function store_page(path, page)
    if type(page) ~= "table" then return false end

    local ok, json_string = pcall(json_encode, page)
    if not ok then
        print("Warning: Could not encode page to JSON for path: " .. path)
        return false
    end

    local f = io.open(path, "wb")
    if not f then return false end

    f:write(json_string)
    f:close()
    return true
end

--- Saves one or all pages of a database to the disk.
-- @param db The database object.
-- @param page_name (Optional) The name of a specific page to save.
db_methods.save = function(db, page_name)
    local db_path = path_pool[db]
    if not db_path then return false end

    -- Save a specific page
    if page_name then
        if type(page_name) == "string" and type(db[page_name]) == "table" then
            return store_page(db_path .. "/" .. page_name, db[page_name])
        else
            return false -- Invalid page name or page data
        end
    end

    -- Save all pages
    for name, page_data in pairs(db) do
        -- We only store tables, avoiding attempts to save other value types
        if type(page_data) == "table" then
            if not store_page(db_path .. "/" .. name, page_data) then
                return false -- Stop and return false on first failure
            end
        end
    end

    return true
end

-- Metatable for all database objects.
local db_metatable = {
    -- Lazy-loads pages when they are accessed for the first time.
    __index = function(db, key)
        -- First, check if a method is being called (e.g., db:save())
        if db_methods[key] then
            return db_methods[key]
        end

        -- If not a method, try to load a page from disk.
        local db_path = path_pool[db]
        local page_path = db_path .. "/" .. key

        if is_file(page_path) then
            local page_data = load_page(page_path)
            if page_data then
                -- Cache the loaded page in the db table
                rawset(db, key, page_data)
                return page_data
            end
        end

        -- Return nil if no method and no page file exists
        return nil
    end
}

-- Publicly accessible table to extend DB methods.
flatdb.hack = db_methods

-- Set the metatable for the main `flatdb` module.
setmetatable(flatdb, {
    -- Allows `flatdb` to be called as a function: `flatdb(path)`
    __call = function(_, path)
        assert(is_dir(path), "'" .. path .. "' is not a valid directory.")

        -- Return cached DB object if it already exists
        if db_pool[path] then
            return db_pool[path]
        end

        -- Create a new database object
        local db = {}
        setmetatable(db, db_metatable)

        -- Store the new db object and its path for future reference
        db_pool[path] = db
        path_pool[db] = path

        return db
    end
})

return flatdb
