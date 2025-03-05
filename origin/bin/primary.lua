local component = require("component")
local shell = require("shell")

local args = shell.parse(...)
if #args == 0 then
  io.write("用法: primary <类型> [<地址>]\n")
  io.write("注意地址可以为缩写。\n")
  return 1
end

local componentType = args[1]

if #args > 1 then
  local address = args[2]
  if not component.get(address) then
    io.stderr:write("该地址不存在对应组件\n")
    return 1
  else
    component.setPrimary(componentType, address)
    os.sleep(0.1) -- 让信号得以处理
  end
end
if component.isAvailable(componentType) then
  io.write(component.getPrimary(componentType).address, "\n")
else
  io.stderr:write("该类型无首选组件\n")
  return 1
end
