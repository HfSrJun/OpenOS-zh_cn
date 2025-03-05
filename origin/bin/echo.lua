local args, options = require("shell").parse(...)
if options.help then
  io.write([[
`echo`可将提供的一或多个字符串输出到标准输出中。
  -n      不输出自动换行符
  -e      启用解析转义字符
  --help  显示该帮助信息并退出
]])
  return
end
if options.e then
  for index,arg in ipairs(args) do
    -- 在此处用到了Lua来解析转义序列，如\27。而没有编写自己的语言来自行解析。
    -- 请注意在真实的终端里用\e代表\27。
    args[index] = assert(load("return \"" .. arg:gsub('"', [[\"]]) .. "\""))()
  end
end
io.write(table.concat(args," "))
if not options.n then
  io.write("\n")
end
