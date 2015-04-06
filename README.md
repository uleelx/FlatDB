FlatDB
===========

FlatDB is a lua library that implements a serverless, zero-configuration, NoSQL database engine.<br>
It provides a key-value storage system using plain Lua tables.

When To Use FlatDB
===========

When you want to use SQLite to store data, just take a glance at FlatDB.<br>
When Lua acts in your program as the major language or the embedded scripting language, just try using FlatDB.

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

2. Open or create a book
```lua
if not db.book then
	db.book = {}
end
```

3. Store key-value items
```lua
db.book.key = 'value'
-- equivalent to db.book['key'] = 'value'
```

4. Retrieve items
```lua
print(db.book.key) -- prints 'value'
```

5. Save to file
```lua
db:save()
-- 'book' will be saved to './db/book'
```

More usage can be found in the *cli.lua*(a Redis-like command line interface example using FlatDB).

Quick Look
==========

```lua
local flatdb = require("flatdb")

-- open a directory as a database, 'db' is just a plain empty Lua table that can contain books
local db = flatdb("./db")

-- open or create a book named "default", it also a plain empty Lua table where key-value data stored in
if not db.default then
	db.default = {}
end

-- extend db methods for getting values from 'default' book
flatdb.hack.get = function(db, key)
	return db.default[key]
end

-- extend db methods for setting values to 'default' book
flatdb.hack.set = function(db, key, value)
	db.default[key] = value
end

-- extend db methods for watching new key
flatdb.hack.guard = function(db, f)
	setmetatable(db.default, {__newindex = f})
end

-- get key-value data from 'default' book
print(db:get("hello"))

-- set key-value data to 'default' book
db:set("hello", "world")

-- get key-value data from 'default' book
print(db:get("hello"))

-- set guard function
db:guard(function(book, key, value)
	print("CREATE KEY permission denied!")
end)

-- try creating new key-value data to 'default' book
db:set("key1", 1)
db:set("key2", 2)

-- update an existing key-value item
db:set("hello", "bye")

print(db:get("key1")) -- prints nil
print(db:get("key2")) -- prints nil
print(db:get("hello")) -- prints 'bye'

-- store 'default' book to './db/default' file
db:save()

```

API
==========

- **Functions**

  - **flatdb(dir) --> db**

      Bind a directory as a database, returns nil if 'dir' doesn't exists. Otherwise, it returns a 'db' obeject.

  - **db:save([book])**

      Save all books or the given book(if specified) contained in db to file. The 'book' argument is a string, the book's name.

- **Tables**

  - **flatdb.hack**

      The 'hack' table contains db's methods. There is only one method 'save(db, book)' in it by default.
      It is usually used to extend db methods.

Dependencies
=======

- [pp](https://github.com/luapower/pp)
- [lfs](http://keplerproject.github.io/luafilesystem/)

All above libraries can be found in [LuaPower](https://luapower.com/).

License
=======

FlatDB is distributed under the MIT license.
