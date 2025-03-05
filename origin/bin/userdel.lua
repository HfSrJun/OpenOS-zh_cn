local computer = require("computer")
local shell = require("shell")

local args = shell.parse(...)
if #args ~= 1 then
  io.write("用法: userdel <用户名>\n")
  return 1
end

if not computer.removeUser(args[1]) then
  io.stderr:write("用户不存在\n")
  return 1
end
