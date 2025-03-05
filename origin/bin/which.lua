local shell = require("shell")

local args = shell.parse(...)
if #args == 0 then
  io.write("用法: which <程序名>\n")
  return 255
end

for i = 1, #args do
  local result, reason = shell.resolve(args[i], "lua")

  if not result then
    result = shell.getAlias(args[i])
    if result then
      result = args[i] .. ": 是" .. result .. "的别名" 
    end
  end

  if result then
    print(result)
  else
    io.stderr:write(args[i] .. ": " .. reason .. "\n")
    return 1
  end
end
