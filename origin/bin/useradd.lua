local computer = require("computer")
local shell = require("shell")

local args = shell.parse(...)
if #args ~= 1 then
  io.write("用法: useradd <用户名>\n")
  return 1
end

local result, reason = computer.addUser(args[1])
if not result then
  io.stderr:write(reason..'\n')
  return 1
end
