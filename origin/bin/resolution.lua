local shell = require("shell")
local tty = require("tty")

local args = shell.parse(...)
local gpu = tty.gpu()

if #args == 0 then
  local w, h = gpu.getViewport()
  io.write(w," ",h,"\n")
  return
end

if #args ~= 2 then
  print("用法: resolution [<宽度> <高度>]")
  return
end

local w = tonumber(args[1])
local h = tonumber(args[2])
if not w or not h then
  io.stderr:write("宽度或高度无效\n")
  return 1
end

local result, reason = gpu.setResolution(w, h)
if not result then
  if reason then -- 否则未进行任何更改
    io.stderr:write(reason..'\n')
  end
  return 1
end
tty.clear()
