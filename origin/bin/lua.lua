local shell = require("shell")
local args = shell.parse(...)

if #args == 0 then
  args = {"/lib/core/lua_shell.lua"}
end

local filename = args[1]
local buffer, script, reason
buffer = io.lines(filename, "*a")()
if buffer then
  buffer = buffer:gsub("^#![^\n]+", "") -- 如果有shebang则移除
  script, reason = load(buffer, "="..filename)
else
  reason = string.format("无法打开%s进行读取", filename)
end

if not script then
  io.stderr:write(tostring(reason) .. "\n")
  os.exit(false)
end

buffer, reason = pcall(script, table.unpack(args, 2))
if not buffer then
  io.stderr:write(type(reason) == "table" and reason.reason or tostring(reason), "\n")
  os.exit(false)
end
