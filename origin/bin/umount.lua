local fs = require("filesystem")
local shell = require("shell")

local args, options = shell.parse(...)

if #args < 1 then
  io.write("用法: umount [-a] <挂载>\n")
  io.write(" -a  解卦标签或地址指定的文件系统，而不是由挂载路径指定。注意地址可以为缩写。\n")
  return 1
end

local proxy, reason
if options.a then
  proxy, reason = fs.proxy(args[1])
  if proxy then
    proxy = proxy.address
  end
else
  local path = shell.resolve(args[1])
  proxy, reason = fs.get(path)
  if proxy then
    proxy = reason -- = path
    if proxy ~= path then
      io.stderr:write("不是挂载点\n")
      return 1
    end
  end
end
if not proxy then
  io.stderr:write(tostring(reason)..'\n')
  return 1
end

if not fs.umount(proxy) then
  io.stderr:write("没有可解挂的对象\n")
  return 1
end
