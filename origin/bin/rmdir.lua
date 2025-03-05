local shell = require("shell")
local fs =  require("filesystem")
local text = require("text")

local args, options = shell.parse(...)

local function usage()
  print(
[[用法: rmdir [选项]... 目录...
删除一或多个目录，目录需要为空。

  -q, --ignore-fail-on-non-empty
                  忽略因为目录非空导致的操作失败
  -p, --parents   删除目录及其各级为空的父目录
                  如'rmdir -p a/b/c'相当于'rmdir a/b/c a/b a'
  -v, --verbose   每次处理目录时都输出状态信息
      --help      显示该提示文本并退出]])
end

if options.help then
  usage()
  return 0
end

if #args == 0 then
  io.stderr:write("rmdir: 缺少操作对象\n")
  return 1
end

options.p = options.p or options.parents
options.v = options.v or options.verbose
options.q = options.q or options['ignore-fail-on-non-empty']

local ec = 0
local function ec_bump()
  ec = 1
  return 1
end

local function remove(path, ...)
  -- 结束递归的检查
  if path == nil then
    return true
  end

  if options.v then
    print(string.format('rmdir: 正在删除目录%s', path))
  end

  local rpath = shell.resolve(path)
  if path == '.' then
    io.stderr:write('rmdir: 删除目录\'.\'失败: 无效参数\n')
    return ec_bump()
  elseif not fs.exists(rpath) then
    io.stderr:write("rmdir: 无法删除" .. path .. ": 路径不存在\n")
    return ec_bump()
  elseif fs.isLink(rpath) or not fs.isDirectory(rpath) then
    io.stderr:write("rmdir: 无法删除" .. path .. ": 不是目录\n")
    return ec_bump()
  else
    local list, reason = fs.list(rpath)

    if not list then
      io.stderr:write(tostring(reason)..'\n')
      return ec_bump()
    else
      if list() then
        if not options.q then
          io.stderr:write("rmdir: 无法删除" .. path .. ": 目录非空\n")
        end
        return ec_bump()
      else
        -- 路径存在且为空？
        local ok, reason = fs.remove(rpath)
        if not ok then
          io.stderr:write(tostring(reason)..'\n')
          return ec_bump(), reason
        end
        return remove(...) -- 最后的return会返回其余所有数据
      end
    end
  end
end

for _,path in ipairs(args) do
  -- 清理输入
  path = path:gsub('/+', '/')

  local segments = {}
  if options.p and path:len() > 1 and path:find('/') then
    local chain = text.split(path, {'/'}, true)
    local prefix = ''
    for _,e in ipairs(chain) do
      table.insert(segments, 1, prefix .. e)
      prefix = prefix .. e .. '/'
    end
  else
    segments = {path}
  end

  remove(table.unpack(segments))
end

return ec
