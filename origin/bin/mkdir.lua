local fs = require("filesystem")
local shell = require("shell")

local args = shell.parse(...)
if #args == 0 then
  io.write("用法: mkdir <目录名1> [<目录名2> [...]]\n")
  return 1
end

local ec = 0
for i = 1, #args do
  local path = shell.resolve(args[i])
  local result, reason = fs.makeDirectory(path)
  if not result then
    if not reason then
      if fs.exists(path) then
        reason = "已存在相同名称的文件或文件夹"
      else
        reason = "原因未知"
      end
    end
    io.stderr:write("mkdir: 无法创建目录'" .. tostring(args[i]) .. "': " .. reason .. "\n")
    ec = 1
  end
end

return ec
