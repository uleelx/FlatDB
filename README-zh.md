FlatDB
===========

FlatDB是一个Lua扩展库，实现一个无服务器的零配置的NoSQL数据引擎。<br>
它提供一个由Lua表构成的键值对存储系统。

FlatDB的使用情境
===========

当您想使用SQLite存储一些数据，而不必用到SQL查询的时候，可以考虑使用FlatDB代替之。<br>
如果您的程序使用的语言恰好是Lua，或者嵌入了Lua作为扩展脚本的话，那么就尝试使用FlatDB来存储数据吧。

概念
==========

|     FlatDB     |     磁盘     |   Lua      |
|:--------------:|:------------:|:----------:|
| 数据库         | 目录        | 表         |
| 页（Page）     | 文件          | 表         |
| 键值对         | 文件内容      | 键值对     |

该表反映的是FlatDB、磁盘和Lua三个层面的对应关系。<br>
FlatDB将一个目录看作数据库，映射到一个Lua表上。
该Lua表的下级也是一些Lua表，对应FlatDB的页（Page），它将被存储到数据库目录下同名的文件中。
这些文件的内容正是页（Page）中的键值对，即Lua表序列化后的字符串。
键值对中的键和值可以是Lua中所有能够被序列化的类型，即除了协程、用户数据、C数据和C函数外的类型。

用法
==========

将*flatdb.lua*文件复制到你的项目所在或存储Lua扩展库的目录中。<br>
然后在用到它的Lua文件中写上这句话：
```lua
local flatdb = require 'flatdb'
```

1. 将目录作为数据库映射到Lua表中

    ```lua
    local db = flatdb('./db')
    ```

2. 打开或创建一个页（Page）

    ```lua
    if not db.page then
    	db.page = {}
    end
    ```

3. 往页（Page）中写入键值对数据

    ```lua
    db.page.key = 'value'
    -- equivalent to db.page['key'] = 'value'
    ```

4. 读取页（Page）中的数据

    ```lua
    print(db.page.key) -- prints 'value'
    ```

5. 将所有页（Page）数据保存在同名的文件中

    ```lua
    db:save()
    -- 'page' will be saved to './db/page'
    ```

更多用法可参考本项目中的*cli.lua*（一个用FlatDB模拟的类Redis命令行客户端例子）。

范例概览
==========

```lua
-- 这是一个以FlatDB作为存储引擎的日志系统例子

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

- **函数**

  - **flatdb(dir) --> db**

      将一个目录dir映射成数据库对象。若目录不存在，返回nil。否则，返回一个数据库对象db（Lua表）。

  - **db:save([page])**

      将指定的页（Page）保存在文件中，若不指定则保存数据库对象中所有的页。参数*page*是指页的名称。

- **表**

  - **flatdb**

      当数据库载入后，flatdb表的键值对有以下关系：

      *flatdb[dir] --> db*

      *flatdb[db] --> dir*

  - **flatdb.hack**

      hack表包含了数据库对象的所有方法。默认情况下，目前数据库对象只有一个db:save([page])方法。
      该表一般用于扩展数据库对象方法。

依赖项
=======

- [pp](https://github.com/luapower/pp)
- [lfs](http://keplerproject.github.io/luafilesystem/)

以上的依赖库都可以在[LuaPower](https://luapower.com/)上找到。

许可证
=======

FlatDB是在MIT许可证下发布的。
