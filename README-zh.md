FlatDB
===========

FlatDB是一个轻量级的Lua扩展库，实现一个无服务器的零配置的NoSQL数据引擎。它提供一个由Lua表构成的键值对存储系统，非常适合嵌入式应用、原型开发和需要持久化存储但不想使用传统数据库复杂性的项目。

**主要特性：**
- **零配置** - 只需指向一个目录即可开始使用
- **无服务器** - 无需数据库服务器，直接使用文件系统
- **人类可读** - 数据以JSON格式存储，可用任何文本编辑器查看
- **轻量级** - 单个Lua文件，依赖极少
- **灵活** - 支持除协程、用户数据、cdata和C函数外的所有Lua数据类型

FlatDB的使用情境
===========

FlatDB适用于以下场景：
- **嵌入式应用** - 游戏、物联网设备、桌面应用
- **原型开发** - 快速实现持久化存储，无需数据库配置
- **配置存储** - 保存用户设置或应用状态
- **日志系统** - 结构化日志存储，便于查询
- **中小规模数据集** - 几千条记录以内
- **Lua优先应用** - 当Lua是主要语言或嵌入式脚本语言时

当您需要简单键值存储且不想配置复杂数据库时，选择FlatDB而不是SQLite。

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

### 安装
将`flatdb.lua`文件复制到你的项目所在或存储Lua扩展库的目录中。

### 基本用法

```lua
local flatdb = require 'flatdb'

-- 1. 先创建目录（必须）
os.execute("mkdir ./db")  -- 或使用 lfs.mkdir 如果有的话

-- 2. 将目录作为数据库映射到Lua表中
local db = flatdb('./db')  -- 目录必须存在，否则会报错

-- 3. 创建或访问页（相当于表/集合）
db.users = {}  -- 创建名为'users'的新页
-- 或者更安全地
-- if not db.users then
--  db.users = {}
-- end

-- 4. 存储数据（支持任何Lua数据类型）
db.users.john = {name = "张三", age = 30, active = true}
db.users.jane = {name = "李四", age = 25, active = false}

-- 5. 检索数据
print(db.users.john.name)  -- 输出: "张三"

-- 6. 保存到磁盘
db:save()  -- 创建文件: ./db/users

-- 7. 重新加载数据（下次运行时）
local same_db = flatdb('./db')
print(same_db.users.john.age)  -- 输出: 30
```

### 高级用法

```lua
-- 只保存特定页
db:save('users')

-- 使用嵌套数据
db.config.app = {
    title = "我的应用",
    version = "1.0.0",
    settings = {
        theme = "dark",
        notifications = true
    }
}
```

更多用法可参考另一个项目[Ledis](https://github.com/uleelx/ledis)（一个使用FlatDB作为存储后端的Redis实现）。

范例概览 - 日志系统示例
==========

这个示例演示如何使用FlatDB构建一个完整的日志系统。该系统按日期和日志级别组织日志，便于查询特定日志。

### 本示例实现的功能
- **创建结构化日志记录器**，将日志保存到`./log/`目录
- **按日期组织日志**（如2024-01-15）和日志级别（debug、info、warn、error、fatal）
- **每10条消息自动保存**，防止数据丢失
- **提供查询方法**，按级别和日期查询日志
- **扩展FlatDB**，添加日志便利方法

### 代码详解

```lua
-- 初始化FlatDB用于日志记录
local flatdb = require("flatdb")
local logger = flatdb("./log")  -- 日志将存储在./log/目录

-- 自动保存的内部计数器
local count = 0

-- 核心日志函数，存储结构化日志条目
local function common_log(logger, level, message)
	local today = os.date("%Y-%m-%d")  -- 当前日期作为键
	
	-- 确保日期和级别表存在
	if logger[today] == nil then logger[today] = {} end
	if logger[today][level] == nil then logger[today][level] = {} end
	
	-- 存储带时间戳的日志条目
	table.insert(logger[today][level], {
		timestamp = os.time(),  -- Unix时间戳
		level = level,          -- 日志级别
		message = message       -- 日志消息
	})
	
	-- 每10条消息自动保存确保持久性
	count = (count+1)%10
	if count == 0 then
		logger:save()
	end
end

-- 定义日志级别
local levels = {"debug", "info", "warn", "error", "fatal"}

-- 扩展FlatDB，添加便利的日志方法
-- 这将添加logger:debug()、logger:info()等方法
for _, level in ipairs(levels) do
	flatdb.hack[level] = function(logger, msg)
		common_log(logger, level, msg)
	end
end

-- 添加按级别和可选日期查询日志的方法
flatdb.hack.find = function(logger, level, date)
	-- 如无提供日期则默认为今天
	date = date or os.date("%Y-%m-%d")
	if logger[date] then
		return logger[date][level]
	end
end

-- 示例用法：记录50条消息（每种级别10条）
for i = 1, 10 do
	logger:debug("这是一条调试消息。")
	logger:info("这是一条信息消息。")
	logger:warn("这是一条警告消息。")
	logger:error("这是一条错误消息。")
	logger:fatal("这是一条致命消息。")
end

-- 查询并显示今天的错误日志
local pp = require("pp") -- 漂亮打印库：https://github.com/luapower/pp
pp(logger:find("error"))
```

### 使用结果
运行此代码后：
- 日志存储在`./log/`目录下的JSON文件中
- 每个日期有单独的文件（如`2024-01-15`）
- 日志按级别组织：debug、info、warn、error、fatal
- 可以查询日志，如：`logger:find("error", "2024-01-15")`

API
==========

- **函数**

  - **flatdb(dir) --> db**

      将一个目录dir映射成数据库对象。**目录必须存在** - 若目录不存在将报错。返回一个数据库对象db（Lua表）。

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

- [json.lua](https://github.com/rxi/json.lua)

许可证
=======

FlatDB是在MIT许可证下发布的。
