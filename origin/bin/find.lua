local shell = require("shell")
local fs = require("filesystem")
local text = require("text")

local USAGE =
[===[用法: find [路径] [--type=[dfs]] [--[i]name=表达式]
  --path  若不指定，假设路径为当前工作目录
  --type  返回给定类型的结果，d：目录，f：文件，s：符号链接
  --name  指定文件名的模式。需要用引号将"*."括起来。iname区分大小写
  --help  显示该帮助信息并退出]===]

local args, options = shell.parse(...)

if (not args or not options) or options.help then
  print(USAGE)
  if not options.help then
    return 1
  else
    return -- 返回nil代表无报错
  end
end

if #args > 1 then
  io.stderr:write(USAGE..'\n')
  return 1
end

local path = #args == 1 and args[1] or "."

local bDirs = true
local bFiles = true
local bSyms = true

local fileNamePattern = ""
local bCaseSensitive = true

if options.iname and options.name then
  io.stderr:write("find程序不能同时定义iname和name\n")
  return 1
end

if options.type then
  bDirs = false
  bFiles = false
  bSyms = false

  if options.type == "f" then
    bFiles = true
  elseif options.type == "d" then
    bDirs = true
  elseif options.type == "s" then
    bSyms = true
  else
    io.stderr:write(string.format("find: 未知的`type`参数: %s\n", options.type))
    io.stderr:write(USAGE..'\n')
    return 1
  end
end

if options.iname or options.name then
  bCaseSensitive = options.iname ~= nil
  fileNamePattern = options.iname or options.name

  if type(fileNamePattern) ~= "string" then
    io.stderr:write('find: `name`缺少参数\n')
    return 1
  end

  if not bCaseSensitive then
    fileNamePattern = fileNamePattern:lower()
  end

  -- 将*的前面加上. 让GNU可以全局查找
  fileNamePattern = text.escapeMagic(fileNamePattern)
  fileNamePattern = fileNamePattern:gsub("%%%*", ".*")
end

local function isValidType(spath)
  if not fs.exists(spath) then
    return false
  end

  if fileNamePattern:len() > 0 then
    local fileName = spath:gsub('.*/','')

    if fileName:len() == 0 then
      return false
    end

    local caseFileName = fileName

    if not bCaseSensitive then
      caseFileName = caseFileName:lower()
    end

    local s, e = caseFileName:find(fileNamePattern)
    if not s or not e then
      return false
    end

    if s ~= 1 or e ~= caseFileName:len() then
      return false
    end
  end

  if fs.isDirectory(spath) then
    return bDirs
  elseif fs.isLink(spath) then
    return bSyms
  else
    return bFiles
  end
end

local function visit(rpath)
  local spath = shell.resolve(rpath)

  if isValidType(spath) then
    local result = rpath:gsub('/+$','')
    print(result)
  end

  if fs.isDirectory(spath) then
    local list_result = fs.list(spath)
    for list_item in list_result do
      visit(rpath:gsub('/+$', '') .. '/' .. list_item)
    end
  end
end

visit(path)
