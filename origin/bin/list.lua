local fs = require("filesystem")
local shell = require("shell")

local args, ops = shell.parse(...)
if #args == 0 then
  table.insert(args, ".")
end

local arg = args[1]
local path = shell.resolve(arg)

if ops.help then
  io.write([[用法: list [路径]
  `路径`:
    为可选参数（默认为`./`）
  显示给定路径下文件的列表，不带额外格式。
  适用于内存较小的设备。
]])
  return 0
end

local real, why = fs.realPath(path)
if real and not fs.exists(real) then
  why = "不存在该文件或目录"
end
if why then
  io.stderr:write(string.format("无法访问'%s': %s", arg, tostring(why)))
  return 1
end

for item in fs.list(real) do
  io.write(item, '\n')
end
