local shell = require("shell")
local transfer = require("tools/transfer")

local args, options = shell.parse(...)
options.h = options.h or options.help
if #args < 2 or options.h then
  io.write([[用法: cp [选项] <来源...> <目标>
 -i: 覆盖文件前进行提示（覆盖-n选项）。
 -n: 不要覆盖现存文件。
 -r: 递归复制目录。
 -u: 只有在目标文件不存在或与源文件不同时才复制。
 -P: 保留属性，如符号链接。preserve attributes, e.g. symbolic links.
 -v: 输出详细信息。
 -x: 仅限在源文件的文件系统内复制。
 --skip=P: 跳过符合Lua正则表达式P的文件。
]])
  return not not options.h
end

-- 清理copy的选项（与move相反）
options =
{
  cmd = "cp",
  i = options.i,
  f = options.f,
  n = options.n,
  r = options.r,
  u = options.u,
  P = options.P,
  v = options.v,
  x = options.x,
  skip = {options.skip},
}

return transfer.batch(args, options)
