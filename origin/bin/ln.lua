local fs = require("filesystem")
local shell = require("shell")

local args = shell.parse(...)
if #args == 0 then
  io.write("用法: ln <目标> [<名称>]\n")
  return 1
end

local target_name = args[1]
local target = shell.resolve(target_name)

-- 不要链接到不存在的目标，除非链接损坏
if not fs.exists(target) and not fs.isLink(target) then
  io.stderr:write("ln: 无法访问'" .. target_name .. "': 不存在该文件或目录\n")
  return 1
end

local linkpath
if #args > 1 then
  linkpath = shell.resolve(args[2])
else
  linkpath = fs.concat(shell.getWorkingDirectory(), fs.name(target))
end

if fs.isDirectory(linkpath) then
  linkpath = fs.concat(linkpath, fs.name(target))
end

local result, reason = fs.link(target_name, linkpath)
if not result then
  io.stderr:write(reason..'\n')
  return 1
end
