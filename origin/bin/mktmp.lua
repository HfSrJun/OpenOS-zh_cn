local fs = require("filesystem")
local shell = require("shell")
local sh = require("sh")

local touch = loadfile(shell.resolve("touch", "lua"))
local mkdir = loadfile(shell.resolve("mkdir", "lua"))

if not touch then
  local errorMessage = "缺少mktmp所需的工具"
  io.stderr:write(errorMessage .. '\n')
  return false, errorMessage
end

local args, ops = shell.parse(...)

local function pop(...)
  local result
  for _,key in ipairs({...}) do
    result = ops[key] or result
    ops[key] = nil
  end
  return result
end

local directory = pop('d')
local verbose = pop('v', 'verbose')
local quiet = pop('q', 'quiet')

if pop('help') or #args > 1 or next(ops) then
  print([[用法: mktmp [选项] [路径]
创建一个名称随机的新文件，存放在$TMPDIR中，或`路径`参数中（给定的话）
  -d              创建目录而不是文件
  -v, --verbose   将结果输出到标准输出，即使没有tty也是如此
  -q, --quiet     不要将结果输出到标准输出，即使存在tty（会被verbose覆盖）
      --help      输出该帮助信息]])
  if next(ops) then
    io.stderr:write("无效选项: " .. (next(ops)) .. '\n')
    return 1
  end
  return
end

if not verbose then
  if not quiet then
    if io.stdout.tty then
      verbose = true
    end
  end
end

local prefix = args[1] or os.getenv("TMPDIR") .. '/'
if not fs.exists(prefix) then
  io.stderr:write(
    string.format(
      "无法在%s创建临时文件或目录，路径不存在\n",
      prefix))
  return 1
end

local tmp = os.tmpname()
local ok, reason = (directory and mkdir or touch)(tmp)

if sh.internal.command_passed(ok) then
  if verbose then
    print(tmp)
  end
  return tmp
end

return ok, reason
