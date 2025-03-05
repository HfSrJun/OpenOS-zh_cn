--[[Lua implementation of the UN*X touch command--]]
local shell = require("shell")
local fs =  require("filesystem")

local args, options = shell.parse(...)

local function usage()
  print(
[[用法: touch [选项]... 文件...
将给定的各个`文件`的修改时间更新为当前时间。
不存在的`文件`参数会创建为空文件，除非指定`-c`。

  -c, --no-create    不要创建文件
      --help         显示该提示文本并退出]])
end

if options.help then
  usage()
  return 0
elseif #args == 0 then
  io.stderr:write("touch: 没有操作对象\n")
  return 1
end

options.c = options.c or options["no-create"]
local errors = 0

for _,arg in ipairs(args) do
  local path = shell.resolve(arg)

  if fs.isDirectory(path) then
    io.stderr:write(string.format("`%s`被忽略: 不支持目录\n", arg))
  else
    local real, reason = fs.realPath(path)
    if real then
      local file
      if fs.exists(real) or not options.c then
        file = io.open(real, "a")
      end
      if not file then
        real = options.c
        reason = "无权限"
      else
        file:close()
      end
    end
    if not real then
      io.stderr:write(string.format("touch: 无法touch`%s`: %s\n", arg, reason))
      errors = 1
    end
  end
end

return errors
