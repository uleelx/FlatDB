FlatDB
===========

FlatDB is a lua library that implements a serverless, zero-configuration, NoSQL database engine.<br>
It provides a key-value storage system using plain Lua tables.

When To Use FlatDB
===========

When you want to use SQLite to store data, just take a glance at FlatDB.<br>
When Lua acts in your program as the major language or the embedded scripting language, just try using FlatDB.

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

Copy *flatdb.lua* file to your project or where your lua libraries stored.<br>
Then write this in any Lua file where you want to use it:
```lua
local flatdb = require 'flatdb'
```

1. Bind a directory as a database

    ```lua
    local db = flatdb('./db')
    ```

2. Open or create a page

    ```lua
    if not db.page then
    	db.page = {}
    end
    ```

3. Store key-value items

    ```lua
    db.page.key = 'value'
    -- equivalent to db.page['key'] = 'value'
    ```

4. Retrieve items

    ```lua
    print(db.page.key) -- prints 'value'
    ```

5. Save to file

    ```lua
    db:save()
    -- 'page' will be saved to './db/page'
    ```

More usage can be found in the *cli.lua*(a Redis-like command line interface example using FlatDB).

Quick Look
==========

```lua
-- This is an logging system example using FlatDB

local flatdb = require("flatdb")

local logger = flatdb("./log")

local count = 0

local function common_log(logger, level, message)
	local today = os.date("%Y-%m-%d")
	if logger[today] == nil then logger[today] = {} end
	if logger[today][level] == nil then logger[today][level] = {} end
	table.insert(logger[today][level], {
		timestamp = os.time(),
		level = level,
		message = message
	})
	count = (count+1)%10
	if count == 0 then
		logger:save()
	end
end

local levels = {"debug", "info", "warn", "error", "fatal"}

for _, level in ipairs(levels) do
	flatdb.hack[level] = function(logger, msg)
		common_log(logger, level, msg)
	end
end

flatdb.hack.find = function(logger, level, date)
	if logger[date or os.date("%Y-%m-%d")] then
		return logger[date or os.date("%Y-%m-%d")][level]
	end
end

for i = 1, 10 do
	logger:debug("This is a debug message.")
	logger:info("This is an info message.")
	logger:warn("This is a warn message.")
	logger:error("This is an error message.")
	logger:fatal("This is a fatal message.")
end

local pp = require("pp")
pp(logger:find("error"))

```

API
==========

- **Functions**

  - **flatdb(dir) --> db**

      Bind a directory as a database, returns nil if 'dir' doesn't exists. Otherwise, it returns a 'db' obeject.

  - **db:save([page])**

      Save all pages or the given page(if specified) contained in db to file. The 'page' argument is a string, the page's name.

- **Tables**

  - **flatdb**

      When a db is loaded, there is two relations below:

      *flatdb[dir] --> db*

      *flatdb[db] --> dir*

  - **flatdb.hack**

      The 'hack' table contains db's methods. There is only one method 'save(db, page)' in it by default.
      It is usually used to extend db methods.

Dependencies
=======

- [pp](https://github.com/luapower/pp)

All above libraries can be found in [LuaPower](https://luapower.com/).

License
=======

FlatDB is distributed under the MIT license.
