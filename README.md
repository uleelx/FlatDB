FlatDB
===========

FlatDB is a lightweight Lua library that implements a serverless, zero-configuration, NoSQL database engine. It provides a simple key-value storage system using plain Lua tables, perfect for embedded applications, prototypes, and projects that need persistent storage without the complexity of traditional databases.

When To Use FlatDB
===========

FlatDB is ideal when you need:
- **Embedded applications** - Games, IoT devices, or desktop apps
- **Prototypes** - Quick persistence without database setup
- **Configuration storage** - Save user settings or app state
- **Logging systems** - Structured log storage with easy querying
- **Small to medium datasets** - Up to a few thousand records
- **Lua-first applications** - When Lua is your primary or embedded scripting language

Choose FlatDB over SQLite when you want simpler setup, human-readable storage, and don't need SQL queries or complex relationships.

Concept
==========

|     FlatDB     |      Disk     |       Lua      |
|:--------------:|:-------------:|:--------------:|
| Database       | Directory     | Table          |
| Page           | File          | Table          |
| Key-value pair | File content  | Key-value pair |

Keys and values can be all Lua types except coroutines, userdata, cdata and C functions.

Usage
==========

### Installation
Copy `flatdb.lua` file to your project or where your Lua libraries are stored.

### Basic Usage

```lua
local flatdb = require 'flatdb'

-- 1. Create directory first (required)
os.execute("mkdir ./db")  -- or use lfs.mkdir if available

-- 2. Bind a directory as a database
local db = flatdb('./db')  -- Directory must exist, will error if not

-- 3. Create or access a page (think of it as a table/collection)
db.users = {}  -- Creates a new page called 'users'
-- or in a safer way
-- if not db.users then
--  db.users = {}
-- end

-- 4. Store data (any Lua data type works)
db.users.john = {name = "John Doe", age = 30, active = true}
db.users.jane = {name = "Jane Smith", age = 25, active = false}

-- 5. Retrieve data
print(db.users.john.name)  -- Output: "John Doe"

-- 6. Save everything to disk
db:save()  -- Creates files: ./db/users

-- 7. Load data back (automatic on next run)
local same_db = flatdb('./db')
print(same_db.users.john.age)  -- Output: 30
```

### Advanced Usage

```lua
-- Save specific page only
db:save('users')

-- Work with nested data
db.config.app = {
    title = "My App",
    version = "1.0.0",
    settings = {
        theme = "dark",
        notifications = true
    }
}
```

More usage can be found in the [Ledis](https://github.com/uleelx/ledis)(an alternative of Redis server using FlatDB).

Quick Look - Logging System Example
==========

This example demonstrates how to build a complete logging system using FlatDB. The system organizes logs by date and log level, making it easy to query specific logs.

### What This Example Does
- **Creates a structured logger** that saves logs to `./log/` directory
- **Organizes logs by date** (e.g., 2024-01-15) and log level (debug, info, warn, error, fatal)
- **Auto-saves every 10 messages** to prevent data loss
- **Provides query methods** to find logs by level and date
- **Extends FlatDB** with custom methods for logging convenience

### Code Breakdown

```lua
-- Initialize FlatDB for logging
local flatdb = require("flatdb")
local logger = flatdb("./log")  -- Logs will be stored in ./log/ directory

-- Internal counter for auto-saving
local count = 0

-- Core logging function that stores structured log entries
local function common_log(logger, level, message)
	local today = os.date("%Y-%m-%d")  -- Current date as key
	
	-- Ensure date and level tables exist
	if logger[today] == nil then logger[today] = {} end
	if logger[today][level] == nil then logger[today][level] = {} end
	
	-- Store log entry with timestamp
	table.insert(logger[today][level], {
		timestamp = os.time(),  -- Unix timestamp
		level = level,          -- Log level
		message = message       -- Log message
	})
	
	-- Auto-save every 10 messages for persistence
	count = (count+1)%10
	if count == 0 then
		logger:save()
	end
end

-- Define log levels
local levels = {"debug", "info", "warn", "error", "fatal"}

-- Extend FlatDB with convenient logging methods
-- This adds logger:debug(), logger:info(), etc.
for _, level in ipairs(levels) do
	flatdb.hack[level] = function(logger, msg)
		common_log(logger, level, msg)
	end
end

-- Add query method to find logs by level and optional date
flatdb.hack.find = function(logger, level, date)
	-- Default to today if no date provided
	date = date or os.date("%Y-%m-%d")
	if logger[date] then
		return logger[date][level]
	end
end

-- Example usage: Log 50 messages (10 of each level)
for i = 1, 10 do
	logger:debug("This is a debug message.")
	logger:info("This is an info message.")
	logger:warn("This is a warn message.")
	logger:error("This is an error message.")
	logger:fatal("This is a fatal message.")
end

-- Query and display error logs for today
local pp = require("pp") -- Pretty printing library: https://github.com/luapower/pp
pp(logger:find("error"))
```

### Usage Results
After running this code:
- Logs are stored in `./log/` directory as JSON files
- Each date gets its own file (e.g., `2024-01-15`)
- Logs are organized by level: debug, info, warn, error, fatal
- You can query logs like: `logger:find("error", "2024-01-15")`

API Reference
==========

### Functions

#### `flatdb(dir) → db`
Binds a directory as a database. **The directory must exist** - will raise an error if it doesn't.

**Parameters:**
- `dir` (string): Path to existing directory that will store your data

**Returns:**
- Database object

**Example:**
```lua
-- Ensure directory exists first
os.execute("mkdir ./mydata")

local db = flatdb('./mydata')  -- Will error if directory doesn't exist
```

#### `db:save([page])`
Saves data to disk. Can save all pages or just a specific page.

**Parameters:**
- `page` (string, optional): Name of specific page to save. If omitted, saves all pages.

**Example:**
```lua
db:save()        -- Save all pages
db:save('users') -- Save only the 'users' page
```

### Tables

#### `flatdb` (global table)
Contains metadata about loaded databases and provides internal mappings.

**Mappings:**
- `flatdb[dir_path] → db_object` - Find database object by directory path
- `flatdb[db_object] → dir_path` - Find directory path by database object

#### `flatdb.hack`
Extension table for adding custom methods to database objects. By default contains only the `save` method.

**Usage:**
```lua
-- Add custom method to all database objects
flatdb.hack.custom_query = function(db, criteria)
    -- Your custom logic here
    return results
end

-- Use custom method
db:custom_query({type = "user"})
```

Dependencies
=======

- [json.lua](https://github.com/rxi/json.lua)

License
=======

FlatDB is distributed under the MIT license, like Lua itself.
