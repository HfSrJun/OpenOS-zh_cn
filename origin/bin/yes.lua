--[[UN*X yes命令的Lua实现--]]
local shell = require("shell")

local args, options = shell.parse(...)

if options.V or options.version then
  io.write("yes v:1.0-3\n")
  io.write("受到GNU coreutils的yes功能启发\n")
  return 0
end

if options.h or options.help then
  io.write("用法: yes [字符串]...\n")
  io.write("或者: yes [-V/h]\n")
  io.write("\n")
  io.write("`yes` 在命令行中输出字符串，或者\"y\",=，直到停止运行。\n")
  io.write("\n")
  io.write("选项:\n")
  io.write("	-V, --version	输出版本信息\n")
  io.write("	-h, --help  	输出该帮助信息\n")
  return 0
end

local msg = #args == 0 and 'y' or table.concat(args, ' ')
msg = msg .. '\n'

while io.write(msg) do
  if io.stdout.tty then
    os.sleep(0)
  end
end
return 0
