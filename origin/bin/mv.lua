local shell = require("shell")
local transfer = require("tools/transfer")

local args, options = shell.parse(...)
options.h = options.h or options.help
if #args < 2 or options.h then
  io.write([[用法: mv [选项] <来源> <目标>
  -f         覆盖前不进行提示
  -i         覆盖前进行提示，除非指定-f
  -v         输出详细信息
  -n         不要覆盖现有文件
  --skip=P   忽略符合Lua正则表达式P的路径
  -h, --help 显示该帮助信息
]])
  return not not options.h
end

-- 清理move的选项（与copy相反）
options =
{
  cmd = "mv",
  f = options.f,
  i = options.i,
  v = options.v,
  n = options.n, -- 不覆盖
  skip = {options.skip},
  P = true, -- move操作一定有保护
  r = true, -- move可以移动整个目录
  x = true, -- 不能移动挂载点
}

return transfer.batch(args, options)
