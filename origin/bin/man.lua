local fs = require("filesystem")
local shell = require("shell")

local args = shell.parse(...)
if #args == 0 then
  io.write("用法: man <主题>\n")
  io.write("`主题`通常是程序或运行库的名称。\n")
  return 1
end

local topic = args[1]
for path in string.gmatch(os.getenv("MANPATH"), "[^:]+") do
  path = shell.resolve(fs.concat(path, topic), "man")
  if path and fs.exists(path) and not fs.isDirectory(path) then
    os.execute(os.getenv("PAGER") .. " " .. path)
    os.exit()
  end
end
io.stderr:write("没有手册条目" .. topic .. '\n')
return 1
